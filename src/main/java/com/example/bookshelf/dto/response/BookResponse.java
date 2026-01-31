package com.example.bookshelf.dto.response;

import com.example.bookshelf.domain.Category;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Schema(description = "도서 응답")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BookResponse {

    @Schema(description = "도서 ID", example = "1")
    private Long id;

    @Schema(description = "도서 제목", example = "클린 코드")
    private String title;

    @Schema(description = "저자", example = "로버트 C. 마틴")
    private String author;

    @Schema(description = "ISBN", example = "9788966260959")
    private String isbn;

    @Schema(description = "출판사", example = "인사이트")
    private String publisher;

    @Schema(description = "가격", example = "33000")
    private BigDecimal price;

    @Schema(description = "재고 수량", example = "100")
    private Integer stockQuantity;

    @Schema(description = "카테고리", example = "TECHNOLOGY")
    private Category category;

    @Schema(description = "카테고리 설명", example = "기술/IT")
    private String categoryDescription;

    @Schema(description = "도서 설명", example = "애자일 소프트웨어 장인 정신")
    private String description;

    @Schema(description = "출판일", example = "2013-12-24")
    private LocalDate publishedDate;

    @Schema(description = "등록일시", example = "2024-01-15T10:30:00")
    private LocalDateTime createdAt;

    @Schema(description = "수정일시", example = "2024-01-15T10:30:00")
    private LocalDateTime updatedAt;
}
