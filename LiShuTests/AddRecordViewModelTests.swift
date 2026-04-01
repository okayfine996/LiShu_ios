1
        let records = try db.context.fetch(FetchDescriptor<Record>())
        #expect(records.count == 1)
        #expect(records[0].recordType == .banquet)
        #expect(records[0].banquetData?.location == "西贝莜面村包间，中档规格")
        #expect(records[0].banquetData?.attendeeList == "主客外还有两位同事陪同")
        #expect(records[0].banquetData?.extraCostNotes == "席间开了两瓶酒")
    }

    @Test func testLoadData() throws {
        let db = try TestDB()
        let c1 = Contact(name: "联系人1", relation: "朋友")
        let c2 = Contact(name: "联系人2", relation: "同事")
        let e1 = Event(name: "婚礼", type: .wedding, date: .now)
        db.context.insert(c1)
        db.context.insert(c2)
        db.context.insert(e1)
        try db.context.save()

        let vm = AddRecordViewModel()
        vm.loadData(context: db.context)

        #expect(vm.allContacts.count == 2)
        #expect(vm.allEvents.count == 1)
    }
}
