package com.example.bookshelf.domain;

public enum Category {
    FICTION("소설"),
    NON_FICTION("비소설"),
    TECHNOLOGY("기술/IT"),
    SCIENCE("과학"),
    HISTORY("역사"),
    SELF_HELP("자기계발");

    private final String description;

    Category(String description) {
        this.description = description;
    }

    public String getDescription() {
        return description;
    }
}
