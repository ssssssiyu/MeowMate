import SwiftUI

struct NotificationView: View {
    var body: some View {
        List {
            // 示例事件
            Text("疫苗接种 - 3天后")
            Text("美容 - 5天后")
            // 显示倒计时
        }
        .navigationTitle("通知")
    }
}