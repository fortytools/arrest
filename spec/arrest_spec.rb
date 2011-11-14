require 'spec_helper'

describe Arrest do
  let(:user) {User.new(:email => 'hans@wurst.de', :password => 'tester')}

  describe 'validation' do
    it 'should be implemented'
    it 'should work'
  end

  describe '#new_record?' do
    it 'should return true if id is nil' do
      user.id = nil
      user.new_record?.should be_true
    end

    it 'should return true if id is empty' do
      user.id = ''
      user.new_record?.should be_true
    end

    it 'should return false if id has been set' do
      user.id = 'whatever'
      user.new_record?.should be_false
    end
  end

  describe '#save' do
    it 'should return true on success' do
      user.save.should eql(true)
    end

    it 'should return false on failure' do
      user.save.should eql(false)
    end

    it 'should persist the object' do
      mock(Arrest::Source.source).post(user)
      user.save
    end
  end

  describe '#update' do
    it 'should raise an ArgumentError when called without options'
    it 'should update a persisted object'
    it 'should not call #save to persist the object'
  end

  describe '#destroy' do
    it 'should destroy a persisted object'
    it 'should raise an Arrest::Errors::DocumentNotPersistedError if the object was not persisted'
  end

  describe '.new' do
    context 'without options' do
      let(:user) {User.new}

      it 'should return a new object' do
        user.should be_kind_of(User)
      end

      it 'should not set undefined attributes' do
        user.email.should be_nil
      end
    end

    context 'with options' do
      let(:user) {User.new(:email => 'hans@wurst.de')}

      it 'should return a new object' do
        user.should be_kind_of(User)
      end

      it 'should set defined attributes' do
        user.email.should eq('hans@wurst.de')
      end

      it 'should not set undefined attributes' do
        user.password.should be_nil
      end
    end
  end

  describe '.create' do
    it 'should initialize and persist an object'
    it 'should return the persisted object'
  end

  describe '.destroy' do
    it 'should raise an ArgumentError when called without options'
    it 'should destroy a persisted object with given id'
    it 'should call .find to get the destroyable object'
  end

  describe '.find' do
    let(:user) do
      User.new(:email => 'hans@wurst.de', :password => 'tester').tap do |u|
        u.save
      end
    end

    it 'should return a persisted object' do
      User.find(user.id).id.should eq(user.id)
    end

    it 'should raise an Arrest::Errors::DocumentNotFoundError if an object cannot be found' do
      expect {User.find('whatever')}.to raise_error(Arrest::Errors::DocumentNotFoundError)
    end

    it 'should raise an ArgumentError when called without options' do
      expect {User.find}.to raise_error(ArgumentError)
    end
  end

  describe '.all' do
    let(:user) do
      User.new(:email => 'hans@wurst.de', :password => 'tester').tap {|u| u.save}
    end

    let(:another_user) do
      User.new(:email => 'fritz@cola.de', :password => 'blub').tap {|u| u.save}
    end

    context 'without options' do
      context 'and without objects being persisted' do
        it 'should return an empty array' do
          User.all.should eq([])
        end
      end

      context 'and with objects being persisted' do
        before do
          user
          another_user
        end

        it 'should return all persisted objects' do
          User.all.size.should eql(2)
        end

        it 'should return objects of same type' do
          User.all.each do |user|
            user.should be_kind_of(User)
          end
        end

        it 'should return objects in order they have been persisted' do
          User.all.map {|user| user.email}.should eq(['hans@wurst.de', 'fritz@cola.de'])
        end
      end
    end
  end
end
