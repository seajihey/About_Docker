package com.example.bookshelf.dto.request;

import com.example.bookshelf.domain.Category;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.*;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.math.BigDecimal;
import java.time.LocalDate;

@Schema(description = "도서 수정 요청")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BookUpdateRequest {

    @Schema(description = "도서 제목", example = "클린 코드 (개정판)")
    @NotBlank(message = "제목은 필수입니다.")
    @Size(max = 200, message = "제목은 200자를 초과할 수 없습니다.")
    private String title;

    @Schema(description = "저자", example = "로버트 C. 마틴")
    @NotBlank(message = "저자는 필수입니다.")
    @Size(max = 100, message = "저자는 100자를 초과할 수 없습니다.")
    private String author;

    @Schema(description = "출판사", example = "인사이트")
    @Size(max = 100, message = "출판사는 100자를 초과할 수 없습니다.")
    private String publisher;

    @Schema(description = "가격", example = "35000")
    @NotNull(message = "가격은 필수입니다.")
    @DecimalMin(value = "0", message = "가격은 0 이상이어야 합니다.")
    @Digits(integer = 8, fraction = 2, message = "가격 형식이 올바르지 않습니다.")
    private BigDecimal price;

    @Schema(description = "카테고리", example = "TECHNOLOGY")
    @NotNull(message = "카테고리는 필수입니다.")
    private Category category;

    @Schema(description = "도서 설명", example = "애자일 소프트웨어 장인 정신 (개정판)")
    private String description;

    @Schema(description = "출판일", example = "2023-12-24")
    private LocalDate publishedDate;
}
