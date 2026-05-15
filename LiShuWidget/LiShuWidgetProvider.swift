import WidgetKit

// MARK: - Timeline Entry

struct LiShuWidgetEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

// MARK: - Timeline Provider

struct LiShuWidgetProvider: TimelineProvider {
    func placeholder(in _: Context) -> LiShuWidgetEntry {
        LiShuWidgetEntry(date: .now, snapshot: .empty)
    }

    func getSnapshot(in _: Context, completion: @escaping (LiShuWidgetEntry) -> Void) {
        completion(LiShuWidgetEntry(date: .now, snapshot: WidgetSnapshotStore.read().refreshed(at: .now)))
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<LiShuWidgetEntry>) -> Void) {
        let snapshot = WidgetSnapshotStore.read().refreshed(at: .now)
        let entry = LiShuWidgetEntry(date: .now, snapshot: snapshot)
        let nextMidnight = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: .now) ?? .now
        )
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}
