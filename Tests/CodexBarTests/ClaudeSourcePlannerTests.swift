import Foundation
import Testing
@testable import CodexBarCore

struct ClaudeSourcePlannerTests {
    @Test
    func `app auto plan preserves ordered steps and reasons`() {
        let plan = ClaudeSourcePlanner.resolve(input: ClaudeSourcePlanningInput(
            runtime: .app,
            selectedDataSource: .auto,
            webExtrasEnabled: false,
            hasWebSession: true,
            hasCLI: true,
            hasDashboardPluginCache: true,
            hasOAuthCredentials: true))

        #expect(plan.orderedSteps.map(\.dataSource) == [.cli, .claudeDashboardPlugin, .log, .oauth])
        #expect(plan.orderedSteps.map(\.inclusionReason) == [
            .appAutoPreferredCLI,
            .autoFallbackDashboardPlugin,
            .autoFallbackLocalLog,
            .autoFallbackOAuthAPI,
        ])
        #expect(plan.availableSteps.map(\.dataSource) == [.cli, .claudeDashboardPlugin, .log, .oauth])
        #expect(plan.preferredStep?.dataSource == .cli)
    }

    @Test
    func `CLI auto plan preserves ordered steps and reasons`() {
        let plan = ClaudeSourcePlanner.resolve(input: ClaudeSourcePlanningInput(
            runtime: .cli,
            selectedDataSource: .auto,
            webExtrasEnabled: false,
            hasWebSession: true,
            hasCLI: true,
            hasDashboardPluginCache: true,
            hasOAuthCredentials: false))

        #expect(plan.orderedSteps.map(\.dataSource) == [.cli, .claudeDashboardPlugin, .log, .oauth])
        #expect(plan.orderedSteps.map(\.inclusionReason) == [
            .cliAutoPreferredCLI,
            .autoFallbackDashboardPlugin,
            .autoFallbackLocalLog,
            .autoFallbackOAuthAPI,
        ])
        #expect(plan.preferredStep?.dataSource == .cli)
    }

    @Test
    func `explicit mode plan is single step`() {
        let plan = ClaudeSourcePlanner.resolve(input: ClaudeSourcePlanningInput(
            runtime: .app,
            selectedDataSource: .cli,
            webExtrasEnabled: true,
            hasWebSession: false,
            hasCLI: true,
            hasDashboardPluginCache: false,
            hasOAuthCredentials: false))

        #expect(plan.orderedSteps.count == 1)
        #expect(plan.orderedSteps.first?.dataSource == .cli)
        #expect(plan.orderedSteps.first?.inclusionReason == .explicitSourceSelection)
        #expect(plan.compatibilityStrategy == ClaudeUsageStrategy(dataSource: .cli, useWebExtras: true))
    }

    @Test
    func `explicit local log mode plan is single step`() {
        let plan = ClaudeSourcePlanner.resolve(input: ClaudeSourcePlanningInput(
            runtime: .app,
            selectedDataSource: .log,
            webExtrasEnabled: true,
            hasWebSession: false,
            hasCLI: true,
            hasDashboardPluginCache: false,
            hasOAuthCredentials: false))

        #expect(plan.orderedSteps.count == 1)
        #expect(plan.orderedSteps.first?.dataSource == .log)
        #expect(plan.orderedSteps.first?.inclusionReason == .explicitSourceSelection)
        #expect(plan.compatibilityStrategy == ClaudeUsageStrategy(dataSource: .log, useWebExtras: false))
    }

    @Test
    func `app auto CLI fallback reports web extras like runtime`() {
        let plan = ClaudeSourcePlanner.resolve(input: ClaudeSourcePlanningInput(
            runtime: .app,
            selectedDataSource: .auto,
            webExtrasEnabled: true,
            hasWebSession: false,
            hasCLI: true,
            hasDashboardPluginCache: false,
            hasOAuthCredentials: false))

        #expect(plan.preferredStep?.dataSource == .cli)
        #expect(plan.compatibilityStrategy == ClaudeUsageStrategy(dataSource: .cli, useWebExtras: true))
    }

    @Test
    func `auto falls back to local logs when CLI is unavailable`() {
        let input = ClaudeSourcePlanningInput(
            runtime: .app,
            selectedDataSource: .auto,
            webExtrasEnabled: false,
            hasWebSession: false,
            hasCLI: false,
            hasDashboardPluginCache: true,
            hasOAuthCredentials: false)
        let plan = ClaudeSourcePlanner.resolve(input: input)

        #expect(plan.orderedSteps.map(\.dataSource) == [.cli, .claudeDashboardPlugin, .log, .oauth])
        #expect(plan.availableSteps.map(\.dataSource) == [.claudeDashboardPlugin, .log])
        #expect(!plan.isNoSourceAvailable)
        #expect(plan.preferredStep?.dataSource == .claudeDashboardPlugin)
        #expect(plan.executionSteps.map(\.dataSource) == [.claudeDashboardPlugin, .log])
        #expect(plan.debugLines() == [
            "planner_order=cli→claude-dashboard-plugin→log→oauth",
            "planner_selected=claude-dashboard-plugin",
            "planner_no_source=false",
            "planner_step.cli=unavailable reason=app-auto-preferred-cli",
            "planner_step.claude-dashboard-plugin=available reason=auto-fallback-dashboard-plugin",
            "planner_step.log=available reason=auto-fallback-local-log",
            "planner_step.oauth=unavailable reason=auto-fallback-oauth-api",
        ])
    }

    @Test
    func `CLI resolver falls back to PATH when Claude CLI path override is invalid`() throws {
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let binaryURL = tempDir.appendingPathComponent("claude")
        try Data("#!/bin/sh\nexit 0\n".utf8).write(to: binaryURL)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: binaryURL.path)

        let resolved = ClaudeCLIResolver.resolvedBinaryPath(
            environment: [
                "CLAUDE_CLI_PATH": "/definitely/missing/claude",
                "PATH": tempDir.path,
            ],
            loginPATH: nil)

        #expect(resolved == binaryURL.path)
    }
}
