module Normalizer
  def normalize_phone ph, c
    PhoneNormalizer.instance.normalize phone, country
  end

  class PhoneNormalizer
    include Singleton
    attr_accessor :country_map
    def initialize
      country_map = {'au' => '+61'}
    end
    def normalize phone, country
      phone.gsub! /\s/, ''
      unless phone[0] == '+'
        phone = country_map[country] + phone[1..-1]
      end
      phone
    end
  end
end
