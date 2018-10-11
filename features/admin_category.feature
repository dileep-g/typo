Feature: Create and Edit Categories
  As a blog administrator
  I want to be able to add or edit blogging categories

  Background:
    Given the blog is set up
    And I am logged into the admin panel

  Scenario: Successfully create category
    Given I am on the Categories page
    When I fill in "category_name" with "Comedy"
    And I fill in "category_keywords" with "Laughing"
    And I fill in "category_description" with "Funny Blogs"
    And I press "Save"
    Then I should be on the Categories page
    Then I should see "Comedy"
    Then I should see "Laughing"
    Then I should see "Funny Blogs"
    
  # Scenario: Successfully edit existing category
    Given I am on the Categories page
    When I follow "Comedy"
    When I fill in "category_name" with "Comedy-extended"
    And I fill in "category_keywords" with "Laughing-extended"
    And I fill in "category_description" with "Funny Blogs extended"
    And I press "Save"
    Then I should be on the Categories page
    Then I should see "Comedy-extended"
    Then I should see "Laughing-extended"
    Then I should see "Funny Blogs extended"