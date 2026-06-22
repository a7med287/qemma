import '../models/book.dart';
import 'api_service.dart';

class BooksService {
  final ApiService _api = ApiService();

  Future<List<Book>> getBooks() async {
    final res = await _api.get('/books');
    final data = res['data'];
    final booksList = data['books'] as List<dynamic>? ?? [];
    return booksList.map((b) => Book.fromJson(b)).toList();
  }

  Future<Map<String, dynamic>> getBook(String bookId) async {
    final res = await _api.get('/books/$bookId');
    return res['data'];
  }
}
