import SwiftUI

let bgColor: Color = .init(red: 0.15, green: 0.15, blue: 0.15)

struct LockScreenView: View {
  let screenName: String
  
  var body: some View {
    VStack {
      Image(systemName: "lock")
      Text(screenName)
        .font(.caption)
        .padding(1)
    }
    .foregroundColor(.accentColor)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(bgColor)
  }
}

#Preview {
  LockScreenView(screenName: "Test")
}
