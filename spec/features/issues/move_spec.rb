require 'rails_helper'

feature 'issue move to another project' do
  let(:user) { create(:user) }
  let(:old_project) { create(:project, :repository) }
  let(:text) { 'Some issue description' }

  let(:issue) do
    create(:issue, description: text, project: old_project, author: user)
  end

  background { sign_in(user) }

  context 'user does not have permission to move issue' do
    background do
      old_project.team << [user, :guest]

      visit issue_path(issue)
    end

    scenario 'moving issue to another project not allowed' do
      expect(page).to have_no_selector('.js-sidebar-move-issue-block')
    end
  end

  context 'user has permission to move issue' do
    let!(:mr) { create(:merge_request, source_project: old_project) }
    let(:new_project) { create(:project) }
    let(:new_project_search) { create(:project) }
    let(:text) { "Text with #{mr.to_reference}" }
    let(:cross_reference) { old_project.to_reference(new_project) }

    background do
      old_project.team << [user, :reporter]
      new_project.team << [user, :reporter]

      visit issue_path(issue)
    end

    scenario 'moving issue to another project', :js do
      find('.js-move-issue').click
      wait_for_requests
      all('.js-move-issue-dropdown-item')[0].click
      find('.js-move-issue-confirmation-button').click

      expect(page).to have_content("Text with #{cross_reference}#{mr.to_reference}")
      expect(page).to have_content("moved from #{cross_reference}#{issue.to_reference}")
      expect(page).to have_content(issue.title)
      expect(page.current_path).to include project_path(new_project)
    end

    scenario 'searching project dropdown', :js do
      new_project_search.team << [user, :reporter]

      find('.js-move-issue').click
      wait_for_requests

      page.within '.js-sidebar-move-issue-block' do
        fill_in('sidebar-move-issue-dropdown-search', with: new_project_search.name)

        expect(page).to have_content(new_project_search.name)
        expect(page).not_to have_content(new_project.name)
      end
    end

    context 'user does not have permission to move the issue to a project', :js do
      let!(:private_project) { create(:project, :private) }
      let(:another_project) { create(:project) }
      background { another_project.team << [user, :guest] }

      scenario 'browsing projects in projects select' do
        find('.js-move-issue').click
        wait_for_requests

        page.within '.js-sidebar-move-issue-block' do
          expect(page).to have_content new_project.name_with_namespace
        end
      end
    end

    context 'issue has been already moved' do
      let(:new_issue) { create(:issue, project: new_project) }
      let(:issue) do
        create(:issue, project: old_project, author: user, moved_to: new_issue)
      end

      scenario 'user wants to move issue that has already been moved' do
        expect(page).to have_no_selector('#move_to_project_id')
      end
    end
  end

  def issue_path(issue)
    project_issue_path(issue.project, issue)
  end
end
