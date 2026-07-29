#!/usr/bin/env python3
"""Generate the bundled Korean administrative-area search catalog.

Input: SGIS SIDO/SIGUNGU shapefiles in Korea 2000 Unified CRS.
Output: a compact WGS84 JSON catalog; raw shapefiles are never committed.

Example:
  python3 -m pip install -r Tools/AdministrativeArea/requirements.txt
  python3 Tools/AdministrativeArea/generate_administrative_areas.py \
    --sido /path/to/bnd_sido_00_2025_2Q.shp \
    --sigungu /path/to/bnd_sigungu_00_2025_2Q.shp \
    --output Rodi/Resources/Data/korean_administrative_areas.json
"""

from __future__ import annotations

import argparse
import json
from collections import Counter, defaultdict
from datetime import date
from pathlib import Path
from typing import Any

import shapefile
from pyproj import CRS, Transformer
from shapely.geometry import shape as make_geometry
from shapely.ops import transform, unary_union


SGIS_SOURCE = "https://www.data.go.kr/data/15129688/fileData.do"

SIDO_DISPLAY_NAMES = {
    "서울특별시": "서울시",
    "부산광역시": "부산시",
    "대구광역시": "대구시",
    "인천광역시": "인천시",
    "광주광역시": "광주시",
    "대전광역시": "대전시",
    "울산광역시": "울산시",
    "세종특별자치시": "세종시",
    "강원특별자치도": "강원도",
    "전북특별자치도": "전라북도",
    "제주특별자치도": "제주도",
}

LEVEL_ORDER = {"sido": 0, "municipalCity": 1, "sigungu": 2}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--sido", required=True, type=Path)
    parser.add_argument("--sigungu", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--base-date", default="20250630")
    return parser.parse_args()


def canonical_sido_name(name: str) -> str:
    return SIDO_DISPLAY_NAMES.get(name, name)


def read_features(
    path: Path,
    code_field: str,
    name_field: str,
) -> tuple[str, list[dict[str, Any]]]:
    reader = shapefile.Reader(str(path), encoding="utf-8")
    crs = Path(path.with_suffix(".prj")).read_text(encoding="utf-8")
    fields = [field[0] for field in reader.fields[1:]]
    features = []

    for record, source_shape in zip(reader.records(), reader.shapes()):
        values = dict(zip(fields, record))
        features.append(
            {
                "code": str(values[code_field]),
                "name": str(values[name_field]),
                "geometry": make_geometry(source_shape.__geo_interface__),
            }
        )

    return crs, features


def coordinate_for(geometry: Any, transformer: Transformer) -> tuple[float, float, tuple[float, float, float, float]]:
    geometry_wgs84 = transform(transformer.transform, geometry)
    point = geometry_wgs84.representative_point()
    return round(point.y, 7), round(point.x, 7), geometry_wgs84.bounds


def serialized_bounds(bounds: tuple[float, float, float, float]) -> dict[str, float]:
    min_longitude, min_latitude, max_longitude, max_latitude = bounds
    return {
        "southWestLatitude": round(min_latitude, 7),
        "southWestLongitude": round(min_longitude, 7),
        "northEastLatitude": round(max_latitude, 7),
        "northEastLongitude": round(max_longitude, 7),
    }


def zoom_level(bounds: tuple[float, float, float, float]) -> int:
    min_longitude, min_latitude, max_longitude, max_latitude = bounds
    span = max(max_longitude - min_longitude, max_latitude - min_latitude)

    if span >= 3.0:
        return 7
    if span >= 1.2:
        return 8
    if span >= 0.6:
        return 9
    if span >= 0.25:
        return 10
    if span >= 0.10:
        return 11
    if span >= 0.04:
        return 12
    if span >= 0.015:
        return 13
    return 14


def compact(value: str) -> str:
    return "".join(value.split())


def add_alias(aliases: set[str], value: str | None) -> None:
    if not value:
        return
    aliases.add(value)
    aliases.add(compact(value))


def sido_aliases(raw_name: str, display_name: str) -> list[str]:
    aliases: set[str] = set()
    add_alias(aliases, raw_name)
    add_alias(aliases, display_name)

    for suffix in ("특별자치도", "특별자치시", "특별시", "광역시", "도", "시"):
        if raw_name.endswith(suffix):
            add_alias(aliases, raw_name.removesuffix(suffix))
        if display_name.endswith(suffix):
            add_alias(aliases, display_name.removesuffix(suffix))

    if raw_name == "전북특별자치도":
        add_alias(aliases, "전북")
        add_alias(aliases, "전라북도")

    return sorted(aliases)


def region_name_variants(*names: str | None) -> set[str]:
    variants: set[str] = set()
    for name in names:
        if not name:
            continue
        variants.add(name)
        for suffix in ("특별자치도", "특별자치시", "특별시", "광역시", "도", "시"):
            if name.endswith(suffix):
                variants.add(name.removesuffix(suffix))

    if "전북특별자치도" in names:
        variants.update({"전북", "전라북도"})

    return variants


def area_aliases(area: dict[str, Any]) -> list[str]:
    aliases: set[str] = set()
    add_alias(aliases, area["displayName"])
    add_alias(aliases, area["baseName"])
    add_alias(aliases, area.get("sourceName"))
    add_alias(aliases, area.get("parentName"))
    add_alias(aliases, area.get("parentSourceName"))

    parent_name = area.get("parentName")
    parent_source_name = area.get("parentSourceName")
    for parent in region_name_variants(parent_name, parent_source_name):
        if parent:
            add_alias(aliases, f"{parent} {area['baseName']}")
            add_alias(aliases, f"{parent} {area.get('sourceName', area['baseName'])}")

    return sorted(aliases)


def display_names(areas: list[dict[str, Any]]) -> None:
    counts = Counter(area["baseName"] for area in areas)

    for area in areas:
        if counts[area["baseName"]] > 1 and area.get("parentName"):
            area["displayName"] = f"{area['parentName']} {area['baseName']}"
        else:
            area["displayName"] = area["baseName"]


def build_catalog(args: argparse.Namespace) -> dict[str, Any]:
    sido_crs, sido_features = read_features(args.sido, "SIDO_CD", "SIDO_NM")
    sigungu_crs, sigungu_features = read_features(args.sigungu, "SIGUNGU_CD", "SIGUNGU_NM")
    if sido_crs != sigungu_crs:
        raise ValueError("SIDO and SIGUNGU coordinate systems do not match")

    source_crs = CRS.from_wkt(sido_crs)
    transformer = Transformer.from_crs(source_crs, "EPSG:4326", always_xy=True)

    sido_by_code: dict[str, dict[str, Any]] = {}
    areas: list[dict[str, Any]] = []
    for feature in sido_features:
        display_name = canonical_sido_name(feature["name"])
        latitude, longitude, bounds = coordinate_for(feature["geometry"], transformer)
        area = {
            "id": feature["code"],
            "level": "sido",
            "baseName": display_name,
            "sourceName": feature["name"],
            "parentName": None,
            "parentSourceName": None,
            "latitude": latitude,
            "longitude": longitude,
            "zoomLevel": zoom_level(bounds),
            "bounds": serialized_bounds(bounds),
        }
        sido_by_code[feature["code"]] = area
        areas.append(area)

    sigungu_candidates: list[dict[str, Any]] = []
    municipal_geometries: dict[tuple[str, str], list[Any]] = defaultdict(list)
    for feature in sigungu_features:
        sido_code = feature["code"][:2]
        parent = sido_by_code.get(sido_code)
        if parent is None:
            raise ValueError(f"Missing SIDO for SIGUNGU {feature['code']}")

        # 세종시는 시도와 시군구가 같은 범위라 중복 선택지를 만들지 않는다.
        if canonical_sido_name(feature["name"]) == parent["baseName"]:
            continue

        latitude, longitude, bounds = coordinate_for(feature["geometry"], transformer)
        candidate = {
            "id": feature["code"],
            "level": "sigungu",
            "baseName": feature["name"],
            "sourceName": feature["name"],
            "parentName": parent["baseName"],
            "parentSourceName": parent["sourceName"],
            "latitude": latitude,
            "longitude": longitude,
            "zoomLevel": zoom_level(bounds),
            "bounds": serialized_bounds(bounds),
        }
        sigungu_candidates.append(candidate)

        if "시 " in feature["name"] and feature["name"].endswith("구"):
            city_name = feature["name"].split(" ", maxsplit=1)[0]
            municipal_geometries[(sido_code, city_name)].append(feature["geometry"])

    municipal_candidates: list[dict[str, Any]] = []
    for (sido_code, city_name), geometries in municipal_geometries.items():
        parent = sido_by_code[sido_code]
        merged = unary_union(geometries)
        latitude, longitude, bounds = coordinate_for(merged, transformer)
        municipal_candidates.append(
            {
                "id": f"municipal-{sido_code}-{city_name}",
                "level": "municipalCity",
                "baseName": city_name,
                "sourceName": city_name,
                "parentName": parent["baseName"],
                "parentSourceName": parent["sourceName"],
                "latitude": latitude,
                "longitude": longitude,
                "zoomLevel": zoom_level(bounds),
                "bounds": serialized_bounds(bounds),
            }
        )

    areas.extend(municipal_candidates)
    areas.extend(sigungu_candidates)
    display_names(areas)

    result = []
    for area in areas:
        aliases = sido_aliases(area["sourceName"], area["baseName"]) if area["level"] == "sido" else area_aliases(area)
        result.append(
            {
                "id": area["id"],
                "level": area["level"],
                "displayName": area["displayName"],
                "parentName": area["parentName"],
                "aliases": aliases,
                "latitude": area["latitude"],
                "longitude": area["longitude"],
                "zoomLevel": area["zoomLevel"],
                **area["bounds"],
            }
        )

    result.sort(key=lambda area: (LEVEL_ORDER[area["level"]], area["displayName"], area["id"]))
    return {
        "metadata": {
            "source": "SGIS 행정구역 통계 및 경계",
            "sourceURL": SGIS_SOURCE,
            "baseDate": args.base_date,
            "generatedAt": date.today().isoformat(),
            "coordinateReferenceSystem": "EPSG:4326",
            "sidoCount": len(sido_features),
            "sigunguCount": len(sigungu_candidates),
            "municipalCityCount": len(municipal_candidates),
        },
        "areas": result,
    }


def main() -> None:
    args = parse_args()
    catalog = build_catalog(args)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(
        "Generated "
        f"{len(catalog['areas'])} areas "
        f"(sido={catalog['metadata']['sidoCount']}, "
        f"municipalCity={catalog['metadata']['municipalCityCount']}, "
        f"sigungu={catalog['metadata']['sigunguCount']})"
    )


if __name__ == "__main__":
    main()
