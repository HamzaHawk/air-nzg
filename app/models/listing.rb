class Listing < ActiveRecord::Base
  belongs_to :user
  has_many :unavailable_ranges
  has_many :bookings
  has_many :photos
  
  before_save :default_amenities
  
  validates :title, presence: true, uniqueness: true
  validates :home_type, :room_type, :accomodates, :term, :city, :price, :address,
             presence: true

  validates :home_type, inclusion: { in: %w(apartment house mansion cave),
                                     message: "Not a valid home type."}
  validates :room_type, inclusion: { in: %w(whole private shared),
                                     message: "Not a valid room type."}

  def self.find_by_params_hash(params)
    listings = Listing.includes(:unavailable_ranges).includes(:photos)

    if params[:city].present?
     listings = listings.where(city: params[:city].downcase)
    end

    if params[:accomodates].present?
     listings = listings.where("accomodates >= ?", params[:accomodates])
    end

    if params[:room_type].present?
     listings = listings.where(room_type: params[:room_type])
    end

    if params[:low_price].present? && params[:high_price].present?
     listings = listings.where(
       "price >= ? AND price <= ?",
       params[:low_price],
       params[:high_price]
     )
    end

    if params[:term].present?
     listings = listings.where(term: params[:term])
    end

    if params[:home_type].present?
     listings = listings.where(home_type: params[:home_type])
    end

    [:essentials, :tv, :cable, :ac, :heat, :kitchen, :internet, :wifi].each do |amenity|
     if params[amenity].present? && params[amenity]
       listings = listings.where(amenity => true)
     end
    end

    if params[:start].present? && params[:end].present?
     listings = listings.includes(:unavailable_ranges).select do |listing|
       listing.available_range?(params[:start], params[:end])
     end
    end
    
    listings
  end

  def available_range?(start_date, end_date)
    return false if self.unavailable_ranges
      .where.not("start_date >= ? AND end_date <= ?", start_date, end_date)
      .any?

    true
  end
  
  def amenities
    amen_arr = []
    
    amen_arr << "Essentials" if self.essentials
    amen_arr << "Television" if self.tv
    amen_arr << "Cable TV" if self.cable
    amen_arr << "Air Conditioning" if self.ac
    amen_arr << "Heat" if self.heat
    amen_arr << "Kitchen" if self.kitchen
    amen_arr << "Wired Internet" if self.internet
    amen_arr << "WiFi" if self.wifi
    
    amen_arr
  end
  
  def cover_pic
    photos.where(cover: true).order(:created_at).first
  end
  
  def new_cover_pic=(photo_data)
    photos.create!(attachment: photo_data, cover: true)
  end
  
  def new_photos=(photo_data_arr)
    photo_data_arr.each do |photo_data|
      photos.create!(attachment: photo_data, cover: false)
    end
  end
  
  def new_unavail_range=(range_arr)
    unavailable_ranges.create!(
      start_date: range_arr[0],
      end_date: range_arr[1] 
    )
  end
  
  private
  
  def default_amenities
    self.essentials ||= false
    self.tv ||= false
    self.cable ||= false
    self.ac ||= false
    self.heat ||= false
    self.kitchen ||= false
    self.internet ||= false
    self.wifi ||= false
    
    nil
  end
end
