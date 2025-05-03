import SwiftUI

let bgColor: Color = .init(red: 0.15, green: 0.15, blue: 0.15)
let bgColorText: Color = .init(red: 0.30, green: 0.30, blue: 0.30)

struct LockScreenView: View {
  let screenName: String

  var body: some View {
    VStack {
      Spacer()

      VStack {
        Image(systemName: "lock")
        Text(screenName)
          .font(.callout)
          .padding(2)
      }
      .foregroundColor(.accentColor)
      .padding(.top, 50)

      Spacer()

      Text("Press ⌘ + Shift + S to unlock")
        .font(.footnote)
        .foregroundColor(bgColorText)
        .padding(.bottom, 20)
    }

    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(bgColor)
  }
}

#Preview {
  LockScreenView(screenName: "Test")
}
