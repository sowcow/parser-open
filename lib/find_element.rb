#extend nokogiri's nodeset to be able to find elements by text
module Nokogiri
  module XML
    class NodeSet
      def containing regex
        self.select do |node|
          node.text[regex]
        end
      end
    end
  end
end

