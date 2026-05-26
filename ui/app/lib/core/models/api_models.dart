class ApiEnvelope<T> {
  ApiEnvelope({
    required this.success,
    required this.message,
    required this.data,
  });

  final bool success;
  final String message;
  final T? data;

  factory ApiEnvelope.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    final raw = json['data'];
    return ApiEnvelope<T>(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      data: raw is Map<String, dynamic> ? fromJsonT(raw) : null,
    );
  }
}

class PagedApiEnvelope<T> {
  PagedApiEnvelope({
    required this.success,
    required this.message,
    required this.data,
    required this.pagination,
  });

  final bool success;
  final String message;
  final T? data;
  final PaginationMeta pagination;

  factory PagedApiEnvelope.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic) fromJsonT,
  ) {
    return PagedApiEnvelope<T>(
      success: json['success'] == true,
      message: (json['message'] ?? '').toString(),
      data: fromJsonT(json['data']),
      pagination: PaginationMeta.fromJson(
        json['pagination'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class PaginationMeta {
  PaginationMeta({
    required this.pageNumber,
    required this.pageSize,
    required this.totalCount,
    required this.totalPages,
  });

  final int pageNumber;
  final int pageSize;
  final int totalCount;
  final int totalPages;

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      pageNumber: (json['pageNumber'] ?? 1) as int,
      pageSize: (json['pageSize'] ?? 20) as int,
      totalCount: (json['totalCount'] ?? 0) as int,
      totalPages: (json['totalPages'] ?? 0) as int,
    );
  }
}
