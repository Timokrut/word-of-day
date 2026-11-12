import SwiftUI

struct WidgetHelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text("Слово —\nна главном экране.")
                        .font(EditorialStyle.headline(36))
                    Text("Выбери маленький или средний виджет. Нажатие на него откроет значение, перевод и примеры.")
                        .foregroundStyle(.secondary).lineSpacing(5)
                    step("1", "Удерживай свободное место на домашнем экране iPhone.")
                    step("2", "Открой меню редактирования и выбери добавление виджета. На некоторых версиях iOS это кнопка «+».")
                    step("3", "Найди word., выбери размер и нажми «Добавить виджет».")
                    Text("Следующее слово запланировано на начало нового дня. Время обновления контролирует iOS.")
                        .font(.footnote).foregroundStyle(.secondary)
                }.padding(28)
            }
            .background(EditorialStyle.paper)
            .navigationTitle("Виджет").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") { dismiss() }
                }
            }
        }.tint(EditorialStyle.blue)
    }

    private func step(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 18) {
            Text(number).font(EditorialStyle.serif(28)).foregroundStyle(EditorialStyle.blue)
            Text(text).frame(maxWidth: .infinity, alignment: .leading).lineSpacing(4)
        }
    }
}
