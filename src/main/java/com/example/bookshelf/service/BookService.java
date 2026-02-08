package com.example.bookshelf.service;

import com.example.bookshelf.domain.Category;
import com.example.bookshelf.dto.request.BookCreateRequest;
import com.example.bookshelf.dto.request.BookUpdateRequest;
import com.example.bookshelf.dto.response.BookListResponse;
import com.example.bookshelf.dto.response.BookResponse;
import org.springframework.data.domain.Pageable;

public interface BookService {

    /**
     * 도서 등록
     */
    BookResponse createBook(BookCreateRequest request);

    /**
     * 도서 상세 조회
     */
    BookResponse getBook(Long id);

    /**
     * ISBN으로 도서 조회
     */
    BookResponse getBookByIsbn(String isbn);

    /**
     * 도서 목록 조회 (페이징)
     */
    BookListResponse getBooks(Pageable pageable);

    /**
     * 카테고리별 도서 조회
     */
    BookListResponse getBooksByCategory(Category category, Pageable pageable);

    /**
     * 키워드 검색 (제목, 저자)
     */
    BookListResponse searchBooks(String keyword, Pageable pageable);

    /**
     * 도서 수정
     */
    BookResponse updateBook(Long id, BookUpdateRequest request);

    /**
     * 재고 수량 변경
     */
    BookResponse updateStock(Long id, Integer quantity);

    /**
     * 도서 삭제
     */
    void deleteBook(Long id);
}
