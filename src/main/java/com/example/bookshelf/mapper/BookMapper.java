package com.example.bookshelf.mapper;

import com.example.bookshelf.domain.Book;
import com.example.bookshelf.dto.request.BookCreateRequest;
import com.example.bookshelf.dto.response.BookResponse;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.ReportingPolicy;

import java.util.List;

@Mapper(componentModel = "spring", unmappedTargetPolicy = ReportingPolicy.IGNORE)
public interface BookMapper {

    Book toEntity(BookCreateRequest request);

    @Mapping(target = "categoryDescription", expression = "java(book.getCategory().getDescription())")
    BookResponse toResponse(Book book);

    List<BookResponse> toResponseList(List<Book> books);
}
