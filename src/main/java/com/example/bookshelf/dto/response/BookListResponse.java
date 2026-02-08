package com.example.bookshelf.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

import java.util.List;

@Schema(description = "도서 목록 응답")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BookListResponse {

    @Schema(description = "도서 목록")
    private List<BookResponse> books;

    @Schema(description = "현재 페이지 번호", example = "0")
    private int pageNumber;

    @Schema(description = "페이지 크기", example = "10")
    private int pageSize;

    @Schema(description = "전체 요소 수", example = "100")
    private long totalElements;

    @Schema(description = "전체 페이지 수", example = "10")
    private int totalPages;

    @Schema(description = "첫 페이지 여부", example = "true")
    private boolean first;

    @Schema(description = "마지막 페이지 여부", example = "false")
    private boolean last;
}
