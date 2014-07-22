require 'minitest/autorun'
require 'active_record'
require 'active_record/diff'

ActiveRecord::Base.establish_connection('adapter' => 'sqlite3', 'database' => ':memory:')

ActiveRecord::Schema.define do
  create_table :people do |table|
    table.column :name, :string
    table.column :email_address, :string
    table.column :company_id, :integer
    table.column :post_count, :integer
  end
end

describe 'ActiveRecord::Diff' do
  before do
    @person = Class.new(ActiveRecord::Base) do
      self.table_name = :people

      include ActiveRecord::Diff
    end

    @person.create! :name => 'alice', :email_address => 'alice@example.com', :company_id => 3, :post_count => 5
    @person.create! :name => 'bob', :email_address => 'bob@example.com', :company_id => 4, :post_count => 0
    @person.create! :name => 'eve', :email_address => 'bob@example.com', :company_id => 4, :post_count => 0

    @people = @person.all

    @alice, @bob, @eve = *@people
  end

  describe 'diff method' do
    it 'returns a hash of the differences between the attributes of the records' do
      @bob.diff(@alice).must_equal({:name => %w( bob alice ), :email_address => %w( bob@example.com alice@example.com )})

      @bob.diff(@eve).must_equal({:name => %w( bob eve )})
    end

    it 'excludes and includes attributes as specified by the diff class method' do
      @person.diff :include => [:id], :exclude => [:email_address]

      @alice.diff(@bob).must_equal({:id => [1, 2], :name => %w( alice bob )})
    end

    it 'uses the list of attributes specified by the diff class method' do
      @person.diff :id, :name

      @alice.diff(@bob).must_equal({:id => [1, 2], :name => %w( alice bob )})
    end

    it 'includes all attributes if specified' do
      @person.diff :include => :all, :exclude => [:email_address]

      @alice.diff(@bob).must_equal({
        :id => [1, 2],
        :name => %w( alice bob ),
        :company_id => [3, 4],
        :post_count => [5, 0]
      })
    end
  end

  describe 'diff method called with a hash argument' do
    it 'returns a hash of the differences between the attributes of the record and the given hash' do
      @bob.diff({:name => 'joe'}).must_equal({:name => %w( bob joe )})
    end
  end

  describe 'diff method called without arguments' do
    it 'returns a hash of the differences when the record has changes' do
      @eve.name = 'bob'

      @eve.diff.must_equal({:name => %w( eve bob )})
    end

    it 'returns an empty hash when the record has no changes' do
      @eve.diff.must_equal({})
    end
  end

  describe 'diff query method' do
    it 'returns true when there are differences between the argument and the receiver' do
      @alice.diff?(@bob).must_equal(true)
    end

    it 'returns true when there are no differences between the argument and the receiver' do
      @alice.diff?(@alice).must_equal(false)
    end
  end

  describe 'diff query method called without arguments' do
    it 'returns true when the record has changes' do
      @alice.diff?(@alice).must_equal(false)
    end

    it 'returns false when the record has no changes' do
      @alice.diff?.must_equal(false)
    end
  end
end
