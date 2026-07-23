////
////  OnboardingView2.swift
////  Rodi
////
////  Created by mac on 7/23/26.
////
//
//import SwiftUI
//
//struct OnboardingView2: View {
//    @StateObject var onboardingStore: StoreOf<OnboardingReducer>
//    
//    @StateObject private var store = Store(
//        state: OnboardingReducer2.State(),
//        reducer: OnboardingReducer2()
//    )
//
//    var body: some View {
//        switch store.state.onboardingStep {
//        case .terms:
//            TermsAgreementView(
//                agreedTerms: onboardingStore.state.agreedTerms,
//                isAllAgreed: onboardingStore.state.isAllTermsAgreed,
//                onToggleAll: { onboardingStore.send(.terms(.toggleAll)) },
//                onToggleTerms: { onboardingStore.send(.terms(.toggle($0))) },
//                onOpenTerms: { onboardingStore.send(.terms(.open($0))) },
//                onNext: { onboardingStore.send(.terms(.nextTapped)) }
//            )
//            
//        case .entry:
//                
//        case .nickname:
//            
//        case .drivingExperience:
//            
//        case .optionalDrivingPreference:
//            
//        case .safety:
//            
//        case .locationPermission:
//            
//        }
//        
//        
//        
//        VStack(spacing: 24) {
//            Text("약관 동의")
//                .font(.title2.bold())
//
//            Button {
//                store.send(.termAgreementTapped)
//            } label: {
//                HStack(spacing: 12) {
//                    Image(systemName: store.state.isTermsAgreed ? "checkmark.circle.fill" : "circle")
//                        .font(.title2)
//                        .foregroundStyle(store.state.isTermsAgreed ? .blue : .secondary)
//
//                    Text("서비스 이용약관에 동의합니다.")
//                        .foregroundStyle(.primary)
//
//                    Spacer()
//                }
//            }
//            .buttonStyle(.plain)
//
//            Button("다음") {
//                // 다음 화면 이동은 아직 추가하지 않습니다.
//            }
//            .buttonStyle(.borderedProminent)
//            .disabled(!store.state.isTermsAgreed)
//        }
//        .padding(24)
//    }
//}
//
//#Preview {
//    OnboardingView2(onboardingStore: <#StoreOf<OnboardingReducer>#>)
//}
