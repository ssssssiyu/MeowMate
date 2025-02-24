import SwiftUI

struct NotificationView: View {
    var body: some View {
        VStack {
            Text("即将到来的事件")
                .font(.largeTitle)
                .padding()
            
            // 示例事件
            List {
                HStack {
                    Text("疫苗接种")
                    Spacer()
                    Text("3天后")
                        .foregroundColor(.gray)
                }
                HStack {
                    Text("美容")
                    Spacer()
                    Text("5天后")
                        .foregroundColor(.gray)
                }
            }
        }
        .navigationTitle("通知")
    }
} 