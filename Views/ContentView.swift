import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                // 显示健康信息和图表
                Text("猫咪健康信息")
                // 用户输入猫咪信息的入口
                Button(action: {
                    // 打开输入界面
                }) {
                    Text("输入猫咪信息")
                }
            }
            .navigationTitle("首页")
        }
    }
}
