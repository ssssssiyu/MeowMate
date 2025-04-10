import SwiftUI
import FirebaseFirestore

struct WeightView: View {
    @State private var weightRecords: [WeightRecord] = []
    @State private var catId: String = ""

    var body: some View {
        VStack {
            TextField("Enter cat ID", text: $catId)
            
            List {
                ForEach(weightRecords.sorted(by: { $0.date > $1.date })) { record in
                    WeightRecordRow(record: record)
                }
                .onDelete(perform: deleteWeight)
            }
        }
    }

    func deleteWeight(at offsets: IndexSet) {
        let recordsToDelete = offsets.map { weightRecords[$0] }
        
        for record in recordsToDelete {
            let db = Firestore.firestore()
            db.collection("cats")
                .document(catId)
                .collection("weights")
                .document(record.id.uuidString)
                .delete() { err in
                    if let err = err {
                        print("Error removing weight record: \(err)")
                    }
                }
        }
        
        weightRecords.remove(atOffsets: offsets)
    }
} 