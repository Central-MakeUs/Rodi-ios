//
//  RodiUserLocationMarkerImages.swift
//  Rodi
//
//  Created by Codex on 7/1/26.
//

import UIKit

#if canImport(KakaoMapsSDK)
import KakaoMapsSDK

extension RodiKakaoMapView {
    func loadSDKMarkerImage(
        relativePath: String,
        fallbackAssetName: String,
        generatedFallback: UIImage,
        logName: String
    ) -> UIImage {
        for bundleName in Constants.sdkMarkerResourceBundleNames {
            if let bundleURL = Bundle.main.url(forResource: bundleName, withExtension: "bundle") {
                let assetURL = bundleURL.appendingPathComponent(relativePath)
                if let image = UIImage(contentsOfFile: assetURL.path) {
                    RodiLogger.info("Kakao user marker asset loaded source=sdk name=\(logName), bundle=\(bundleName), path=\(relativePath), size=\(image.size)")
                    return image
                }
            }
        }

        if let image = UIImage(named: fallbackAssetName) {
            RodiLogger.warning("Kakao user marker asset loaded source=app_fallback name=\(logName), asset=\(fallbackAssetName), size=\(image.size)")
            return image
        }

        RodiLogger.warning("Kakao user marker asset fallback generated name=\(logName), missingSDKPath=\(relativePath), missingAppAsset=\(fallbackAssetName)")
        return generatedFallback
    }

    func makeOrbitingDirectionFanImage(from fanImage: UIImage, bodySize: CGSize) -> UIImage {
        let canvasSide = max(bodySize.width, bodySize.height)
            + fanImage.size.height * 2
            + Constants.userDirectionFanCanvasPadding * 2
        let canvasSize = CGSize(width: canvasSide, height: canvasSide)
        let center = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
        let bodyRadius = min(bodySize.width, bodySize.height) / 2
        let fanOrigin = CGPoint(
            x: center.x - fanImage.size.width / 2,
            y: center.y - bodyRadius - fanImage.size.height + Constants.userDirectionFanOverlap
        )

        let renderer = UIGraphicsImageRenderer(size: canvasSize)
        return renderer.image { _ in
            fanImage.draw(in: CGRect(origin: fanOrigin, size: fanImage.size))
        }
    }

    func makeFallbackUserLocationImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: Constants.fallbackLocationMarkerSize)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: Constants.fallbackLocationMarkerSize)
            let outerRect = rect.insetBy(dx: 10, dy: 10)
            let innerRect = rect.insetBy(dx: 17, dy: 17)

            UIColor(red: 1.0, green: 0.37, blue: 0.22, alpha: 0.18).setFill()
            context.cgContext.fillEllipse(in: rect.insetBy(dx: 4, dy: 4))

            UIColor(red: 1.0, green: 0.42, blue: 0.24, alpha: 1.0).setFill()
            context.cgContext.fillEllipse(in: outerRect)

            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: innerRect)
        }
    }

    func makeFallbackUserDirectionFanImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: Constants.fallbackDirectionFanMarkerSize)
        return renderer.image { context in
            let size = Constants.fallbackDirectionFanMarkerSize
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 6
            let startAngle = CGFloat(-115).degreesToRadians
            let endAngle = CGFloat(-65).degreesToRadians

            let path = UIBezierPath()
            path.move(to: center)
            path.addArc(
                withCenter: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: true
            )
            path.close()

            UIColor(red: 1.0, green: 0.42, blue: 0.24, alpha: 0.32).setFill()
            path.fill()
        }
    }
}

extension UIImage {
    func scaled(by scale: CGFloat) -> UIImage {
        let targetSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
}
#endif
