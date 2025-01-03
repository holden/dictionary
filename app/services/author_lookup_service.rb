class AuthorLookupService
  class NotFoundError < StandardError; end

  def self.find_or_create_author(name)
    # First try to find existing author
    author = Person.find_by("lower(title) = ?", name.downcase)
    return author if author.present?

    # Try ConceptNet first
    concept = ConceptNetService.lookup_person(name)
    if concept.present?
      return Person.create!(
        title: concept.fetch("name"),
        conceptnet_id: concept.fetch("id")
      )
    end

    # Try OpenLibrary as fallback
    author_data = OpenLibraryService.lookup_author(name)
    if author_data.present?
      return Person.create!(
        title: author_data.fetch("name"),
        openlibrary_id: author_data.fetch("key")
      )
    end

    # If we got here, we couldn't find the author in either service
    raise NotFoundError, "Could not verify author '#{name}' in external services"
  end
end 