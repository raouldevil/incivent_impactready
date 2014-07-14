require 'spec_helper'

describe 'Account Activities' do
	before(:each) do
		FactoryGirl.create(:account_option)
	end

	describe 'Account Creation' do
		it 'should not create an account without a name' do
			visit new_account_path
			fill_in 'Name', with: 'Package Deliveries Inc.'
			select 'Test', from: 'Account option'
			click_button 'Create Account'
			page.should have_content('Registration: Step 1')
		end

		it 'should create an account without a name' do
			visit new_account_path
			fill_in 'Name', with: ''
			select 'Test', from: 'Account option'
			click_button 'Create Account'
			page.should have_content("can't be blank")
		end
  end

  describe 'Account Listing' do
  	it 'should list all accounts' do
  		account = FactoryGirl.create(:account)
  		user = FactoryGirl.create(:user, :master_user => true, :god_user => true)
  		priority = FactoryGirl.create(:priority, :account => account)
  		status = FactoryGirl.create(:status, :account => account)
  		type = FactoryGirl.create(:type, :account => account)
  		group = FactoryGirl.create(:group, :account => account)
  	  FactoryGirl.create(:membership, :user => user, :group => group)
  	  visit signin_path
  	  fill_in 'Email', :with => user.email
  	  fill_in 'Password', :with => "mememe"
  	  click_button 'Sign in'

  	  visit accounts_path
  	  page.should have_content(account.name)
  	end
  end

  describe 'Account Editing' do
    before(:each) do
      @account = FactoryGirl.create(:account)
      priority = FactoryGirl.create(:priority, :account => @account)
      status = FactoryGirl.create(:status, :account => @account)
      type = FactoryGirl.create(:type, :account => @account)
    end

    it 'should allow editing for god users' do
      user = FactoryGirl.create(:user, :master_user => true, :god_user => true)
      visit signin_path
      fill_in 'Email', :with => user.email
      fill_in 'Password', :with => "mememe"
      click_button 'Sign in'

      visit accounts_path
      click_link 'Edit'
      fill_in 'Name', :with => 'Environmental Militants!'
      click_button 'Update Account'

      page.should have_content('Environmental Militants!')
    end

    it 'should redirect to subscriptions if the account type is changed' do
      FactoryGirl.create(:account_option, :name => 'Pro', :cost => 40)
      user = FactoryGirl.create(:user, :master_user => true)
      group = FactoryGirl.create(:group, :account => @account)
      FactoryGirl.create(:membership, :user => user, :group => group)
      visit signin_path
      fill_in 'Email', :with => user.email
      fill_in 'Password', :with => "mememe"
      click_button 'Sign in'

      visit account_path(@account)
      click_link 'Edit your Account'
      select 'Pro', :from => 'Account option'
      click_button 'Update Account'

      page.should have_content('Account Activation')
    end

  end

end