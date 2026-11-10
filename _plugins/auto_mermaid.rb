# frozen_string_literal: true

# Automatically enable Mermaid scripts for any post or page containing a ```mermaid block.
Jekyll::Hooks.register [:documents, :pages], :pre_render do |doc|
  if doc.content && doc.content.include?('```mermaid')
    doc.data['mermaid'] ||= {}
    doc.data['mermaid']['enabled'] = true
    doc.data['mermaid']['zoomable'] = true if doc.data['mermaid']['zoomable'].nil?
  end
end
