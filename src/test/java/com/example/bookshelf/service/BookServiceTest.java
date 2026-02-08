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
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.*;
import static org.mockito.BDDMockito.*;

@ExtendWith(MockitoExtension.class)
class BookServiceTest {

    @Mock
    private BookRepository bookRepository;

    @Mock
    private BookMapper bookMapper;

    @InjectMocks
    private BookServiceImpl bookService;

    private Book book;
    private BookCreateRequest createRequest;
    private BookUpdateRequest updateRequest;
    private BookResponse bookResponse;

    @BeforeEach
    void setUp() {
        book = Book.builder()
                .title("클린 코드")
                .author("로버트 C. 마틴")
                .isbn("9788966260959")
                .publisher("인사이트")
                .price(new BigDecimal("33000"))
                .stockQuantity(100)
                .category(Category.TECHNOLOGY)
                .description("애자일 소프트웨어 장인 정신")
                .publishedDate(LocalDate.of(2013, 12, 24))
                .build();

        createRequest = BookCreateRequest.builder()
                .title("클린 코드")
                .author("로버트 C. 마틴")
                .isbn("9788966260959")
                .publisher("인사이트")
                .price(new BigDecimal("33000"))
                .stockQuantity(100)
                .category(Category.TECHNOLOGY)
                .description("애자일 소프트웨어 장인 정신")
                .publishedDate(LocalDate.of(2013, 12, 24))
                .build();

        updateRequest = BookUpdateRequest.builder()
                .title("클린 코드 (개정판)")
                .author("로버트 C. 마틴")
                .publisher("인사이트")
                .price(new BigDecimal("35000"))
                .category(Category.TECHNOLOGY)
                .description("애자일 소프트웨어 장인 정신 (개정판)")
                .publishedDate(LocalDate.of(2023, 12, 24))
                .build();

        bookResponse = BookResponse.builder()
                .id(1L)
                .title("클린 코드")
                .author("로버트 C. 마틴")
                .isbn("9788966260959")
                .publisher("인사이트")
                .price(new BigDecimal("33000"))
                .stockQuantity(100)
                .category(Category.TECHNOLOGY)
                .categoryDescription("기술/IT")
                .description("애자일 소프트웨어 장인 정신")
                .publishedDate(LocalDate.of(2013, 12, 24))
                .build();
    }

    @Nested
    @DisplayName("도서 등록")
    class CreateBook {

        @Test
        @DisplayName("성공적으로 도서를 등록한다")
        void createBook_Success() {
            // given
            given(bookRepository.existsByIsbn(anyString())).willReturn(false);
            given(bookMapper.toEntity(any(BookCreateRequest.class))).willReturn(book);
            given(bookRepository.save(any(Book.class))).willReturn(book);
            given(bookMapper.toResponse(any(Book.class))).willReturn(bookResponse);

            // when
            BookResponse result = bookService.createBook(createRequest);

            // then
            assertThat(result).isNotNull();
            assertThat(result.getTitle()).isEqualTo("클린 코드");
            assertThat(result.getIsbn()).isEqualTo("9788966260959");
            
            then(bookRepository).should().existsByIsbn(createRequest.getIsbn());
            then(bookRepository).should().save(any(Book.class));
        }

        @Test
        @DisplayName("중복 ISBN으로 등록 시 예외가 발생한다")
        void createBook_DuplicateIsbn_ThrowsException() {
            // given
            given(bookRepository.existsByIsbn(anyString())).willReturn(true);

            // when & then
            assertThatThrownBy(() -> bookService.createBook(createRequest))
                    .isInstanceOf(DuplicateIsbnException.class)
                    .hasMessageContaining("9788966260959");
        }
    }

    @Nested
    @DisplayName("도서 조회")
    class GetBook {

        @Test
        @DisplayName("ID로 도서를 조회한다")
        void getBook_Success() {
            // given
            given(bookRepository.findById(anyLong())).willReturn(Optional.of(book));
            given(bookMapper.toResponse(any(Book.class))).willReturn(bookResponse);

            // when
            BookResponse result = bookService.getBook(1L);

            // then
            assertThat(result).isNotNull();
            assertThat(result.getTitle()).isEqualTo("클린 코드");
        }

        @Test
        @DisplayName("존재하지 않는 ID로 조회 시 예외가 발생한다")
        void getBook_NotFound_ThrowsException() {
            // given
            given(bookRepository.findById(anyLong())).willReturn(Optional.empty());

            // when & then
            assertThatThrownBy(() -> bookService.getBook(999L))
                    .isInstanceOf(BookNotFoundException.class);
        }

        @Test
        @DisplayName("도서 목록을 페이징하여 조회한다")
        void getBooks_WithPaging() {
            // given
            Pageable pageable = PageRequest.of(0, 10);
            Page<Book> bookPage = new PageImpl<>(List.of(book), pageable, 1);
            
            given(bookRepository.findAll(any(Pageable.class))).willReturn(bookPage);
            given(bookMapper.toResponseList(anyList())).willReturn(List.of(bookResponse));

            // when
            BookListResponse result = bookService.getBooks(pageable);

            // then
            assertThat(result).isNotNull();
            assertThat(result.getBooks()).hasSize(1);
            assertThat(result.getTotalElements()).isEqualTo(1);
        }
    }

    @Nested
    @DisplayName("도서 수정")
    class UpdateBook {

        @Test
        @DisplayName("성공적으로 도서를 수정한다")
        void updateBook_Success() {
            // given
            given(bookRepository.findById(anyLong())).willReturn(Optional.of(book));
            given(bookMapper.toResponse(any(Book.class))).willReturn(
                    BookResponse.builder()
                            .id(1L)
                            .title("클린 코드 (개정판)")
                            .price(new BigDecimal("35000"))
                            .build()
            );

            // when
            BookResponse result = bookService.updateBook(1L, updateRequest);

            // then
            assertThat(result).isNotNull();
            assertThat(result.getTitle()).isEqualTo("클린 코드 (개정판)");
        }
    }

    @Nested
    @DisplayName("재고 관리")
    class StockManagement {

        @Test
        @DisplayName("재고 수량을 변경한다")
        void updateStock_Success() {
            // given
            given(bookRepository.findById(anyLong())).willReturn(Optional.of(book));
            given(bookMapper.toResponse(any(Book.class))).willReturn(
                    BookResponse.builder()
                            .id(1L)
                            .stockQuantity(50)
                            .build()
            );

            // when
            BookResponse result = bookService.updateStock(1L, 50);

            // then
            assertThat(result.getStockQuantity()).isEqualTo(50);
        }
    }

    @Nested
    @DisplayName("도서 삭제")
    class DeleteBook {

        @Test
        @DisplayName("성공적으로 도서를 삭제한다")
        void deleteBook_Success() {
            // given
            given(bookRepository.findById(anyLong())).willReturn(Optional.of(book));
            willDoNothing().given(bookRepository).delete(any(Book.class));

            // when
            bookService.deleteBook(1L);

            // then
            then(bookRepository).should().delete(book);
        }
    }
}
