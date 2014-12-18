class String
  #get post data from chrome's network eg, and transform it into good format
  def postize 
    post_data = {}
    scanned_a_of_as = self.scan /(\w+)=([\w +]+)/ #[["name", "Elly"], ["submit", "Get+Listing"]]
    scanned_a_of_as.each do |key_value|
      post_data[key_value[0]] = key_value[1]
    end
    post_data
  end


  #monkey patch strip message so that they strip off ANY spaces
  def strip
    self.gsub /\A[[:space:]]+|[[:space:]]+\z/, ''
  end
  def strip!
    self.gsub! /\A[[:space:]]+|[[:space:]]+\z/, ''
  end
end




