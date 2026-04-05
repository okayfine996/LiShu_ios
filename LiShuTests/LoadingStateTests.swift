//
//  LoadingStateTests.swift
//  LiShuTests
//

import Foundation
@testable import LiShu
import Testing

struct LoadingStateTests {
    @Test func idleState() {
        let state: LoadingState<String> = .idle
        #expect(state.isLoading == false)
        #expect(state.value == nil)
        #expect(state.errorMessage == nil)
    }

    @Test func loadingState() {
        let state: LoadingState<String> = .loading
        #expect(state.isLoading == true)
        #expect(state.value == nil)
        #expect(state.errorMessage == nil)
    }

    @Test func loadedState() {
        let state: LoadingState<String> = .loaded("test")
        #expect(state.isLoading == false)
        #expect(state.value == "test")
        #expect(state.errorMessage == nil)
    }

    @Test func errorState() {
        let state: LoadingState<String> = .error("Something went wrong")
        #expect(state.isLoading == false)
        #expect(state.value == nil)
        #expect(state.errorMessage == "Something went wrong")
    }

    @Test func valueExtraction() {
        let loaded: LoadingState<Int> = .loaded(42)
        #expect(loaded.value == 42)

        let idle: LoadingState<Int> = .idle
        #expect(idle.value == nil)
    }

    @Test func errorMessageExtraction() {
        let err: LoadingState<Bool> = .error("Network error")
        #expect(err.errorMessage == "Network error")

        let loaded: LoadingState<Bool> = .loaded(true)
        #expect(loaded.errorMessage == nil)
    }
}
