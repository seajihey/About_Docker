package com.example.bookshelf.controller;

import com.example.bookshelf.domain.Category;
import com.example.bookshelf.dto.request.BookCreateRequest;
import com.example.bookshelf.dto.request.BookUpdateRequest;
import com.example.bookshelf.dto.request.StockUpdateRequest;
import com.example.bookshelf.dto.response.ApiResponse;
import com.example.bookshelf.dto.response.BookListResponse;
import com.example.bookshelf.dto.response.BookResponse;
import com.example.bookshelf.service.BookService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@Tag(name = "Book API", description = "도서 관리 API")
@Slf4j
@RestController
@RequestMapping("/api/v1/books")
@RequiredArgsConstructor
public class BookController {

    private final BookService bookService;

    @Operation(summary = "도서 등록", description = "새로운 도서를 등록합니다.")
    @PostMapping
    public ResponseEntity<ApiResponse<BookResponse>> createBook(
            @Valid @RequestBody BookCreateRequest request) {
        log.info("POST /api/v1/books - Creating book: {}", request.getTitle());
        
        BookResponse response = bookService.createBook(request);
        System.out.println("도서가 등록되었습니다.");
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.success("도서가 등록되었습니다.", response));
    }

    @Operation(summary = "도서 목록 조회", description = "도서 목록을 페이징하여 조회합니다.")
    @GetMapping
    public ResponseEntity<ApiResponse<BookListResponse>> getBooks(
            @PageableDefault(size = 10, sort = "createdAt", direction = Sort.Direction.DESC)
            Pageable pageable) {
        log.info("GET /api/v1/books - Fetching books");
        
        BookListResponse response = bookService.getBooks(pageable);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @Operation(summary = "도서 상세 조회", description = "도서 ID로 상세 정보를 조회합니다.")
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<BookResponse>> getBook(
            @Parameter(description = "도서 ID") @PathVariable Long id) {
        log.info("GET /api/v1/books/{} - Fetching book", id);
        
        BookResponse response = bookService.getBook(id);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @Operation(summary = "ISBN으로 도서 조회", description = "ISBN으로 도서를 조회합니다.")
    @GetMapping("/isbn/{isbn}")
    public ResponseEntity<ApiResponse<BookResponse>> getBookByIsbn(
            @Parameter(description = "ISBN (13자리)") @PathVariable String isbn) {
        log.info("GET /api/v1/books/isbn/{} - Fetching book by ISBN", isbn);
        
        BookResponse response = bookService.getBookByIsbn(isbn);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @Operation(summary = "카테고리별 도서 조회", description = "카테고리별로 도서를 조회합니다.")
    @GetMapping("/category/{category}")
    public ResponseEntity<ApiResponse<BookListResponse>> getBooksByCategory(
            @Parameter(description = "카테고리") @PathVariable Category category,
            @PageableDefault(size = 10, sort = "createdAt", direction = Sort.Direction.DESC)
            Pageable pageable) {
        log.info("GET /api/v1/books/category/{} - Fetching books by category", category);
        
        BookListResponse response = bookService.getBooksByCategory(category, pageable);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @Operation(summary = "도서 검색", description = "제목 또는 저자로 도서를 검색합니다.")
    @GetMapping("/search")
    public ResponseEntity<ApiResponse<BookListResponse>> searchBooks(
            @Parameter(description = "검색 키워드") @RequestParam String keyword,
            @PageableDefault(size = 10, sort = "createdAt", direction = Sort.Direction.DESC)
            Pageable pageable) {
        log.info("GET /api/v1/books/search?keyword={} - Searching books", keyword);
        
        BookListResponse response = bookService.searchBooks(keyword, pageable);
        return ResponseEntity.ok(ApiResponse.success(response));
    }

    @Operation(summary = "도서 수정", description = "도서 정보를 수정합니다.")
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<BookResponse>> updateBook(
            @Parameter(description = "도서 ID") @PathVariable Long id,
            @Valid @RequestBody BookUpdateRequest request) {
        log.info("PUT /api/v1/books/{} - Updating book", id);
        
        BookResponse response = bookService.updateBook(id, request);
        System.out.println("도서가 수정되었습니다.");
        return ResponseEntity.ok(ApiResponse.success("도서가 수정되었습니다.", response));
    }

    @Operation(summary = "재고 수량 변경", description = "도서의 재고 수량을 변경합니다.")
    @PatchMapping("/{id}/stock")
    public ResponseEntity<ApiResponse<BookResponse>> updateStock(
            @Parameter(description = "도서 ID") @PathVariable Long id,
            @Valid @RequestBody StockUpdateRequest request) {
        log.info("PATCH /api/v1/books/{}/stock - Updating stock to {}", id, request.getQuantity());
        
        BookResponse response = bookService.updateStock(id, request.getQuantity());
        System.out.println("재고가 변경되었습니다.");
        return ResponseEntity.ok(ApiResponse.success("재고가 변경되었습니다.", response));
    }

    @Operation(summary = "도서 삭제", description = "도서를 삭제합니다.")
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteBook(
            @Parameter(description = "도서 ID") @PathVariable Long id) {
        log.info("DELETE /api/v1/books/{} - Deleting book", id);
        
        bookService.deleteBook(id);
        System.out.println("도서가 삭제되었습니다.");
        return ResponseEntity.ok(ApiResponse.success("도서가 삭제되었습니다."));
    }
}
