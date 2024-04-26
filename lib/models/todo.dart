class ToDo {
  String? id;
  String? todoText;
  bool isDone;
  ToDo({
    required this.id,
    required this.todoText,
    this.isDone = false,
  });
  static List<ToDo> todoList() {
    return [
      ToDo(id: '01', todoText: 'Passport', isDone: true),
      ToDo(id: '02', todoText: 'Visa', isDone: true),
      ToDo(id: '03', todoText: 'Hotel Reservations'),
      ToDo(id: '04', todoText: 'Money'),
      ToDo(id: '05', todoText: 'Electronics'),
      ToDo(id: '06', todoText: 'Tickets'),
      ToDo(id: '07', todoText: 'Local Currency'),
      ToDo(id: '08', todoText: 'Maps'),
      ToDo(id: '09', todoText: 'Medical Documents'),

    ];
  }
}