with open("Frigo/Cibo/Features/Calendar/FoodCalendarView.swift", "r") as f:
    content = f.read()

old_trash = """                            let items = (viewModel.snapshot?.items ?? []).filter { $0.id == item.id }
                            if let exactItem = items.first {"""
new_trash = """                            if let exactItem = (viewModel.snapshot?.items ?? []).first(where: { $0.id == item.id }) {"""

content = content.replace(old_trash, new_trash)

with open("Frigo/Cibo/Features/Calendar/FoodCalendarView.swift", "w") as f:
    f.write(content)
