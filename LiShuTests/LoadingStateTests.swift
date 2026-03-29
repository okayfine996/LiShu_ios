//
//  LoadingStateTests.swift
//  LiShuTests
//

import Foundation
import Testing
@testable import LiShu

struct LoadingStateTests {

    @Test func testIdleState() {
        let state: LoadingState<String> = .idle
        #expect(state.isLoading == false)
        #expect(state.value == nil)
        #expect(state.errorMessage == nil)
    }

    @Test func testLoadingState() {
        let state: LoadingState<String> = .loading
        #expect(state.isLoading == true)
        #expect(state.value == nil)
        #expect(state.errorMessage == nil)
    }

    @Test func testLoadedState() {
        let state: LoadingState<String> = .loaded("test")
        #expect(state.isLoading == false)
        #expect(state.value == "test")
        #expect(state.errorMessage == nil)
    }

    @Test func testErrorState() {
        let state: LoadingState<String> = .error("Something went wrong")
        #expect(state.isLoading == false)
        #expect(state.value == nil)
        #expect(state.errorMessage == "Something went wrong")
    }

    @Test func testValueExtraction() {
        let loaded: LoadingState<Int> = .loaded(42)
        #expect(loaded.value == 42)

        let idle: LoadingState<Int> = .idle
        #expect(idle.value == nil)
    }

    @Test func testErrorMessageExtraction() {
        let err: LoadingState<Bool> = .error("Network error")
        #expect(err.errorMessage == "Network error")

        let loaded: LoadingState<Bool> = .loaded(true)
        #expect(loaded.errorMessage == nil)
    }
}
