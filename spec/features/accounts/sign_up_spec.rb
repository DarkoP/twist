require "rails_helper"

feature "Accounts" do
  let!(:plan) do
    Plan.create(
      name: "Starter",
      price: 9.95,
      braintree_id: "6w36"
    )
  end

  scenario "creating an account", js: true do
    set_default_host
    visit root_url
    click_link "Create a new account"
    fill_in "Name", with: "Test"
    fill_in "Subdomain", with: "test"
    fill_in "Email", with: "test@example.com"
    fill_in "Password", with: "password"
    fill_in "Password confirmation", with: "password"
    click_button "Next"

    account = Account.last
    expect(account.braintree_customer_id).to be_present
    expect(page.current_url).to eq(choose_plan_url(subdomain: "test"))
    choose "Starter"

    within_frame "braintree-dropin-frame" do
      fill_in "credit-card-number", with: "4242 4242 4242 4242"
      fill_in "expiration", with: "01 / #{Time.now.year + 1}"
      fill_in "cvv", with: "123"
    end

    click_button "Finish"
    sleep(5)

    expect(account.plan).to eq(plan)
    expect(account.braintree_subscription_id).to_not be_blank

    within(".flash_notice") do
      success_message = "Your account has been successfully created."
      expect(page).to have_content(success_message)
    end

    expect(page).to have_content("Signed in as test@example.com")
    expect(page.current_url).to eq(root_url(subdomain: "test"))
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
