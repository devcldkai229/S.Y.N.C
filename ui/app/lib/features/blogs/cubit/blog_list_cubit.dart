import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/features/blogs/data/blog_repository.dart';
import 'package:sync_app/features/blogs/models/blog_models.dart';

enum BlogListStatus { initial, loading, success, failure }

class BlogListState extends Equatable {
  const BlogListState({
    this.status = BlogListStatus.initial,
    this.items = const [],
    this.query = '',
    this.pageNumber = 1,
    this.totalPages = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.error,
  });

  final BlogListStatus status;
  final List<BlogPost> items;
  final String query;
  final int pageNumber;
  final int totalPages;
  final bool hasMore;
  final bool isLoadingMore;
  final String? error;

  BlogListState copyWith({
    BlogListStatus? status,
    List<BlogPost>? items,
    String? query,
    int? pageNumber,
    int? totalPages,
    bool? hasMore,
    bool? isLoadingMore,
    String? error,
  }) {
    return BlogListState(
      status: status ?? this.status,
      items: items ?? this.items,
      query: query ?? this.query,
      pageNumber: pageNumber ?? this.pageNumber,
      totalPages: totalPages ?? this.totalPages,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
    );
  }

  @override
  List<Object?> get props =>
      [status, items, query, pageNumber, totalPages, hasMore, isLoadingMore, error];
}

class BlogListCubit extends Cubit<BlogListState> {
  BlogListCubit(this._repo) : super(const BlogListState());

  final BlogRepository _repo;
  Timer? _debounce;

  Future<void> load() async {
    emit(state.copyWith(status: BlogListStatus.loading, error: null));
    try {
      final page = state.query.trim().isEmpty
          ? await _repo.loadPublished()
          : await _repo.search(q: state.query.trim());
      emit(state.copyWith(
        status: BlogListStatus.success,
        items: page.items,
        pageNumber: page.pageNumber,
        totalPages: page.totalPages,
        hasMore: page.hasMore,
      ));
    } catch (e) {
      emit(state.copyWith(status: BlogListStatus.failure, error: e.toString()));
    }
  }

  void onSearchChanged(String value) {
    _debounce?.cancel();
    emit(state.copyWith(query: value));
    _debounce = Timer(const Duration(milliseconds: 300), () {
      load();
    });
  }

  Future<void> refresh() => load();

  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.status == BlogListStatus.loading) {
      return;
    }
    emit(state.copyWith(isLoadingMore: true));
    try {
      final nextPage = state.pageNumber + 1;
      final page = state.query.trim().isEmpty
          ? await _repo.loadPublished(pageNumber: nextPage)
          : await _repo.search(q: state.query.trim(), pageNumber: nextPage);
      emit(state.copyWith(
        items: [...state.items, ...page.items],
        pageNumber: page.pageNumber,
        totalPages: page.totalPages,
        hasMore: page.hasMore,
        isLoadingMore: false,
      ));
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
