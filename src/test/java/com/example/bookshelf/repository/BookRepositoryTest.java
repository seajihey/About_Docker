package com.example.bookshelf.repository;

import com.example.bookshelf.domain.Book;
import com.example.bookshelf.domain.Category;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.test.context.ActiveProfiles;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;

@DataJpaTest
@ActiveProfiles("test")
class BookRepositoryTest {

    @Autowired
    private BookRepository bookRepository;

    private Book book1;
    private Book book2;

    @BeforeEach
    void setUp() {
        bookRepository.deleteAll();

        book1 = Book.builder()
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

        book2 = Book.builder()
                .title("이펙티브 자바")
                .author("조슈아 블로크")
                .isbn("9788966262281")
                .publisher("인사이트")
                .price(new BigDecimal("36000"))
                .stockQuantity(80)
                .category(Category.TECHNOLOGY)
                .description("자바 플랫폼 모범 사례")
                .publishedDate(LocalDate.of(2018, 11, 1))
                .build();

        bookRepository.save(book1);
        bookRepository.save(book2);
    }

    @Test
    @DisplayName("ISBN으로 도서를 조회한다")
    void findByIsbn() {
        // when
        Optional<Book> result = bookRepository.findByIsbn("9788966260959");

        // then
        assertThat(result).isPresent();
        assertThat(result.get().getTitle()).isEqualTo("클린 코드");
    }

    @Test
    @DisplayName("ISBN 존재 여부를 확인한다")
    void existsByIsbn() {
        // when & then
        assertThat(bookRepository.existsByIsbn("9788966260959")).isTrue();
        assertThat(bookRepository.existsByIsbn("0000000000000")).isFalse();
    }

    @Test
    @DisplayName("카테고리별로 도서를 조회한다")
    void findByCategory() {
        // given
        Book fictionBook = Book.builder()
                .title("1984")
                .author("조지 오웰")
                .isbn("9788937460777")
                .price(new BigDecimal("10800"))
                .category(Category.FICTION)
                .build();
        bookRepository.save(fictionBook);

        // when
        Page<Book> techBooks = bookRepository.findByCategory(
                Category.TECHNOLOGY, PageRequest.of(0, 10));
        Page<Book> fictionBooks = bookRepository.findByCategory(
                Category.FICTION, PageRequest.of(0, 10));

        // then
        assertThat(techBooks.getContent()).hasSize(2);
        assertThat(fictionBooks.getContent()).hasSize(1);
    }

    @Test
    @DisplayName("키워드로 도서를 검색한다 (제목)")
    void searchByKeyword_Title() {
        // when
        Page<Book> result = bookRepository.searchByKeyword(
                "클린", PageRequest.of(0, 10));

        // then
        assertThat(result.getContent()).hasSize(1);
        assertThat(result.getContent().get(0).getTitle()).isEqualTo("클린 코드");
    }

    @Test
    @DisplayName("키워드로 도서를 검색한다 (저자)")
    void searchByKeyword_Author() {
        // when
        Page<Book> result = bookRepository.searchByKeyword(
                "블로크", PageRequest.of(0, 10));

        // then
        assertThat(result.getContent()).hasSize(1);
        assertThat(result.getContent().get(0).getAuthor()).isEqualTo("조슈아 블로크");
    }

    @Test
    @DisplayName("도서 정보를 수정한다")
    void updateBook() {
        // given
        Book savedBook = bookRepository.findByIsbn("9788966260959").orElseThrow();
        
        // when
        savedBook.update(
                "클린 코드 (개정판)",
                "로버트 C. 마틴",
                "인사이트",
                new BigDecimal("35000"),
                Category.TECHNOLOGY,
                "개정판 설명",
                LocalDate.of(2023, 12, 24)
        );
        bookRepository.flush();

        // then
        Book updatedBook = bookRepository.findById(savedBook.getId()).orElseThrow();
        assertThat(updatedBook.getTitle()).isEqualTo("클린 코드 (개정판)");
        assertThat(updatedBook.getPrice()).isEqualByComparingTo(new BigDecimal("35000"));
    }

    @Test
    @DisplayName("재고 수량을 변경한다")
    void updateStock() {
        // given
        Book savedBook = bookRepository.findByIsbn("9788966260959").orElseThrow();
        
        // when
        savedBook.updateStock(50);
        bookRepository.flush();

        // then
        Book updatedBook = bookRepository.findById(savedBook.getId()).orElseThrow();
        assertThat(updatedBook.getStockQuantity()).isEqualTo(50);
    }

    @Test
    @DisplayName("도서를 삭제한다")
    void deleteBook() {
        // given
        long initialCount = bookRepository.count();
        Book savedBook = bookRepository.findByIsbn("9788966260959").orElseThrow();

        // when
        bookRepository.delete(savedBook);

        // then
        assertThat(bookRepository.count()).isEqualTo(initialCount - 1);
        assertThat(bookRepository.findByIsbn("9788966260959")).isEmpty();
    }
}
