package com.example.bookshelf.service;

import com.example.bookshelf.domain.Book;
import com.example.bookshelf.domain.Category;
import com.example.bookshelf.dto.request.BookCreateRequest;
import com.example.bookshelf.dto.request.BookUpdateRequest;
import com.example.bookshelf.dto.response.BookListResponse;
import com.example.bookshelf.dto.response.BookResponse;
import com.example.bookshelf.exception.BookNotFoundException;
import com.example.bookshelf.exception.DuplicateIsbnException;
import com.example.bookshelf.mapper.BookMapper;
import com.example.bookshelf.repository.BookRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Slf4j
@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class BookServiceImpl implements BookService {

    private final BookRepository bookRepository;
    private final BookMapper bookMapper;

    @Override
    @Transactional
    public BookResponse createBook(BookCreateRequest request) {
        log.info("Creating new book with ISBN: {}", request.getIsbn());

        // ISBN 중복 체크
        if (bookRepository.existsByIsbn(request.getIsbn())) {
            throw new DuplicateIsbnException(request.getIsbn());
        }

        Book book = bookMapper.toEntity(request);
        Book savedBook = bookRepository.save(book);

        log.info("Book created successfully with ID: {}", savedBook.getId());
        return bookMapper.toResponse(savedBook);
    }

    @Override
    public BookResponse getBook(Long id) {
        log.debug("Fetching book with ID: {}", id);
        
        Book book = findBookById(id);
        return bookMapper.toResponse(book);
    }

    @Override
    public BookResponse getBookByIsbn(String isbn) {
        log.debug("Fetching book with ISBN: {}", isbn);
        
        Book book = bookRepository.findByIsbn(isbn)
                .orElseThrow(() -> new BookNotFoundException(
                        String.format("ISBN '%s'에 해당하는 도서를 찾을 수 없습니다.", isbn)));
        
        return bookMapper.toResponse(book);
    }

    @Override
    public BookListResponse getBooks(Pageable pageable) {
        log.debug("Fetching books with pageable: {}", pageable);
        
        Page<Book> bookPage = bookRepository.findAll(pageable);
        return toBookListResponse(bookPage);
    }

    @Override
    public BookListResponse getBooksByCategory(Category category, Pageable pageable) {
        log.debug("Fetching books by category: {}", category);
        
        Page<Book> bookPage = bookRepository.findByCategory(category, pageable);
        return toBookListResponse(bookPage);
    }

    @Override
    public BookListResponse searchBooks(String keyword, Pageable pageable) {
        log.debug("Searching books with keyword: {}", keyword);
        
        Page<Book> bookPage = bookRepository.searchByKeyword(keyword, pageable);
        return toBookListResponse(bookPage);
    }

    @Override
    @Transactional
    public BookResponse updateBook(Long id, BookUpdateRequest request) {
        log.info("Updating book with ID: {}", id);
        
        Book book = findBookById(id);
        
        book.update(
                request.getTitle(),
                request.getAuthor(),
                request.getPublisher(),
                request.getPrice(),
                request.getCategory(),
                request.getDescription(),
                request.getPublishedDate()
        );

        log.info("Book updated successfully with ID: {}", id);
        return bookMapper.toResponse(book);
    }

    @Override
    @Transactional
    public BookResponse updateStock(Long id, Integer quantity) {
        log.info("Updating stock for book ID: {} to quantity: {}", id, quantity);
        
        Book book = findBookById(id);
        book.updateStock(quantity);

        log.info("Stock updated successfully for book ID: {}", id);
        return bookMapper.toResponse(book);
    }

    @Override
    @Transactional
    public void deleteBook(Long id) {
        log.info("Deleting book with ID: {}", id);
        
        Book book = findBookById(id);
        bookRepository.delete(book);

        log.info("Book deleted successfully with ID: {}", id);
    }

    private Book findBookById(Long id) {
        return bookRepository.findById(id)
                .orElseThrow(() -> new BookNotFoundException(id));
    }

    private BookListResponse toBookListResponse(Page<Book> bookPage) {
        return BookListResponse.builder()
                .books(bookMapper.toResponseList(bookPage.getContent()))
                .pageNumber(bookPage.getNumber())
                .pageSize(bookPage.getSize())
                .totalElements(bookPage.getTotalElements())
                .totalPages(bookPage.getTotalPages())
                .first(bookPage.isFirst())
                .last(bookPage.isLast())
                .build();
    }
}
