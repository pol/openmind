class Allocation < ActiveRecord::Base
  has_many :votes,  :dependent => :destroy      
  
  validates_presence_of :quantity
  validates_length_of :comments, :maximum => 255
  validates_numericality_of :quantity, :only_integer => true, 
    :allow_nil => false, :minimum => 1
  
  def self.inheritance_column
    'allocation_type'
  end
  
  def available_quantity
    quantity - votes.size
  end
  
  def self.expiring_allocation_days(user)
    min(first_expiration_days(user.active_allocations), 
      first_expiration_days(user.enterprise.active_allocations))
  end
  
  def self.list_all_for_user(user, page, per_page)
    paginate :page => page, 
      :conditions => ["(allocation_type = 'UserAllocation' and allocations.user_id = ?) or (allocation_type = 'EnterpriseAllocation' and enterprise_id = ?)",
      user.id, user.enterprise.id],
      :order => 'allocations.created_at DESC,  allocations.enterprise_id ASC, allocations.user_id  ASC' ,
      :per_page => per_page, :include => :votes
  end

  def self.list(page, per_page)
    paginate :page => page, 
      :order => 'allocations.created_at DESC,  allocations.enterprise_id ASC, allocations.user_id  ASC' ,
      :per_page => per_page, :include => :votes
  end

  def can_delete?
    votes.empty?
  end
  
  private
  
  def self.first_expiration_days(allocations)
    expiring_days = 9999
    if !allocations.nil?
      for allocation in allocations
        if allocation.available_quantity > 0
          l_expiring_days = allocation.expiration_date.jd - Date.today.jd
          if l_expiring_days < expiring_days and l_expiring_days >= 0
            expiring_days = l_expiring_days
          end          
        end
      end
    end
    expiring_days
  end
  
  def self.min(val1, val2)
    return val1 if val1 < val2
    val2
  end

  protected 
  def validate
    errors.add(:quantity, "should be at least 1 or greater") if quantity.nil?  || quantity < 1
    errors.add(:quantity, "must be greater than the votes used, which is #{votes.size}") if quantity < votes.size
  end
end