require "rails_helper"

feature "Accounts" do
  let!(:plan) do
    Plan.create(
      name: "Starter", 
      price: "9.99",
      braintree_id: "starter",
    )
  end

  scenario "creating an account", js: true do
    no_subdomain
    visit root_url
    click_link "Create a new account"
    fill_in "Name", with: "Test"
    fill_in "Subdomain", with: "test"
    fill_in "Email", with: "test@example.com"
    fill_in "Password", with: "password"
    fill_in "Password confirmation", with: "password"
    within_frame 'braintree-dropin-frame' do
      fill_in 'credit-card-number', with: "4111 1111 1111 1111"
      fill_in 'expiration', with: "01 / #{Time.now.year + 1}"
    end
    click_button "Create Account"

    success_message = "Your account has been successfully created."
    expect(page).to have_content(success_message)
    expect(page).to have_content("Signed in as test@example.com")
    expect(page.current_url).to eq("http://test.lvh.me/")
  end

  scenario "Ensure subdomain uniqueness" do
    Account.create!(subdomain: "test", name: "Test")

    visit root_path
    click_link "Create a new account"
    fill_in "Name", with: "Test"
    fill_in "Subdomain", with: "test"
    fill_in "Email", with: "test@example.com"
    fill_in "Password", with: "password"
    fill_in "Password confirmation", with: 'password'

    click_button "Create Account"

    expect(page.current_url).to eq("http://lvh.me/accounts")
    expect(page).to have_content("Sorry, your account could not be created.")
    subdomain_error = find('.account_subdomain .help-block').text
    expect(subdomain_error).to eq('has already been taken')
  end
end
