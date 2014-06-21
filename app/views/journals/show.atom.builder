xml.instruct!(:xml, version: "1.0", encoding: "utf-8")
xml.feed(xmlns: "http://www.w3.org/2005/Atom") do
  xml.id        "tag:chimerao.com,#{@profile.created_at.year}:journal-#{@profile.id}"
  xml.title     "#{@profile.name}'s Journal"
  xml.subtitle  @profile.bio
  xml.updated   @profile.journals.published.last.published_at.strftime('%FT%H:%M:%SZ') # ISO 8601
  xml.link(rel: :self, href: profile_journals_url(@profile, format: :atom), type: "application/atom+xml")
  xml.link(rel: :alternate, href: profile_journals_url(@profile), type: "text/html")
  xml.icon(paperclip_url(url_for_profile_pic(@profile, size: :pixels_128))) if @profile.has_profile_pic?
  xml.logo(paperclip_url(@profile.banner_image(:preview))) if @profile.has_banner_image?
  xml.rights "Copyright (c) #{Time.now.year} #{@profile.name}"

  xml.entry do
    if @journal.is_published?
      xml.id        "tag:chimerao.com,#{@journal.published_at.year}:journal-#{@profile.id}.#{@journal.id}"
      xml.published @journal.published_at.strftime('%FT%H:%M:%SZ')
    end
    xml.updated   @journal.updated_at.strftime('%FT%H:%M:%SZ')
    xml.title     @journal.title
    xml.link(rel: :self, href: journal_url(@journal, format: :atom), type: "application/atom+xml")
    xml.link(rel: :alternate, href: journal_url(@journal), type: "text/html")
    xml.rights "Copyright (c) #{@journal.created_at.year} #{@profile.name}"
    xml.author do
      xml.name @profile.name
      xml.uri  profile_home_url(@profile.url_name)
    end
    @journal.tag_list.each do |tag|
      xml.category tag
    end
    xml.content(imaginate_format(@journal.body), type: "html", 'xml:base' => "#{request.protocol}#{request.host_with_port}/", 'xml:lang' => :en)
  end

end