require_relative 'old_school_api_utils'

module OldSchool

  class ResponseError < StandardError
  end

  class API
    include APIUtils
    def initialize(host, id, secret)
      @host = host
      @id = id
      @secret = secret
      @token = nil
    end

    #Assignment Resource
    def get_assignment(assignment_id)
      hash_from_successful_response get("/powerschool-ptg-api/v2/assignment/#{assignment_id}"), 'assignment'
    end

    def get_assignments(assignment_ids)
      get_many assignment_ids, 'assignment', ->(id){"/powerschool-ptg-api/v2/assignment/#{id}"}
    end

    def update_assignment(assignment_id, assignment)
      put "/powerschool-ptg-api/v2/assignment/#{assignment_id}", {assignment: assignment}.to_json
    end

    def delete_assignment(assignment_id)
      delete "/powerschool-ptg-api/v2/assignment/#{assignment_id}"
    end

    def update_student_assignment_score(assignment_id, student_id, assignment_score)
      put "/powerschool-ptg-api/v2/assignment/#{assignment_id}/student/#{student_id}/score", {assignment_score: assignment_score}.to_json
    end

    def get_student_assignment_score(assignment_id, student_id)
      hash_from_successful_response get("/powerschool-ptg-api/v2/assignment/#{assignment_id}/student/#{student_id}/score"), 'assignment_score'
    end

    def get_student_assignment_scores(assignment_id, student_ids)
      get_many student_ids, 'assignment_score', ->(id){"/powerschool-ptg-api/v2/assignment/#{assignment_id}/student/#{id}/score"}
    end

    def update_multiple_student_assignment_scores(assignment_id, assignment_scores)
      put "/powerschool-ptg-api/v2/assignment/#{assignment_id}/score", {assignment_scores: {assignment_score: assignment_scores}}.to_json
    end

    def get_multiple_student_assignment_scores(assignment_id)
      hash_from_successful_response get("/powerschool-ptg-api/v2/assignment/#{assignment_id}/score"), %w(assignment_scores assignment_score)
    end

    def delete_assignment_score(assignment_id, student_id)
      delete "/powerschool-ptg-api/v2/assignment/#{assignment_id}/student/#{student_id}/scores"
    end

    #School Resource
    def get_students_by_school(school_id)
      num_students = get_students_count_by_school(school_id)
      get_with_pagination_url('student', num_students) {|page| "/ws/v1/school/#{school_id}/student?page=#{page}"}
    end

    def get_students_count_by_school(school_id)
      hash_from_successful_response get("/ws/v1/school/#{school_id}/student/count"), %w(resource count)
    end

    def get_staff_by_school(school_id)
      num_staff = get_staff_count_by_school(school_id)
      get_with_pagination_url('staff', num_staff) {|page| "/ws/v1/school/#{school_id}/staff?page=#{page}"}
    end

    def get_staff_count_by_school(school_id)
      hash_from_successful_response get("/ws/v1/school/#{school_id}/staff/count"), %w(resource count)
    end

    def get_sections_by_school(school_id, start_year = nil)
      num_sections = get_section_count_by_school(school_id, start_year)
      get_with_pagination_url('section', num_sections) do |page| 
        url = "/ws/v1/school/#{school_id}/section?page=#{page}"
        url += "&q=term.start_year==#{start_year}" unless start_year.nil?
      end
    end

    def get_section_count_by_school(school_id, start_year = nil)
      url = "/ws/v1/school/#{school_id}/section/count"
      url += "?q=term.start_year==#{start_year}" unless start_year.nil?
      hash_from_successful_response get(url), %w(resource count)
    end

    def get_terms_by_school(school_id, start_year = nil)
      num_terms = get_terms_count_by_school(school_id, start_year)
      get_with_pagination_url('term', num_terms) do |page| 
        url = "/ws/v1/school/#{school_id}/term?page=#{page}"
        url += "&q=start_year==#{start_year}" unless start_year.nil?
      end
    end

    def get_terms_count_by_school(school_id, start_year = nil)
      url = "/ws/v1/school/#{school_id}/term/count"
      url += "?q=start_year==#{start_year}" unless start_year.nil?
      hash_from_successful_response get(url), %w(resource count)
    end

    def get_courses_by_school(school_id)
      num_courses = get_course_count_by_school(school_id)
      get_with_pagination_url('course', num_courses) {|page| "/ws/v1/school/#{school_id}/course?page=#{page}"}
    end

    def get_course_count_by_school(school_id)
      hash_from_successful_response get("/ws/v1/school/#{school_id}/course/count"), %w(resource count)
    end

    def get_schools_in_current_district
      num_schools = get_school_count_in_current_district
      get_with_pagination_url('school', num_schools) {|page| "/ws/v1/district/school?page=#{page}"}
    end

    def get_school_count_in_current_district
      hash_from_successful_response get('/ws/v1/district/school/count'), %w(resource count)
    end

    def get_school_by_id(school_id)
      hash_from_successful_response get("/ws/v1/school/#{school_id}"), 'school'
    end

    def get_current_district
      hash_from_successful_response get('/ws/v1/district'), 'district'
    end

    #Section Enrollment Resource
    def get_section_enrollment_by_id(section_enrollment_id)
      hash_from_successful_response get("/ws/v1/section_enrollment/#{section_enrollment_id}"), 'section_enrollment'
    end

    #Section Resource
    def add_assignment_to_section(section_id, assignment)
      response = post "/powerschool-ptg-api/v2/section/#{section_id}/assignment", {assignment: assignment}.to_json
      assignment_id_from_response response
    end

    def self.assignment_id_from_response(response_body)
      tokens = response_body.options[:response_headers].split(/[\s\/]/)
      assignment_index = tokens.index('assignment')
      if !assignment_index.nil? and tokens.size > (assignment_index + 1)
        return tokens[assignment_index + 1]
      end
      nil
    end

    def get_section_by_id(section_id)
      hash_from_successful_response get("/ws/v1/section/#{section_id}"),'section'
    end

    def get_section_enrollment_by_section_id(section_id)
      hashes_from_successful_response get("/ws/v1/section/#{section_id}/section_enrollment"), %w(section_enrollments section_enrollment)
    end

    #staff resources
    def get_staff_by_id(staff_id)
      hash_from_successful_response get("/ws/v1/staff/#{staff_id}"), 'staff'
    end

    #student resource
    def get_student_by_id(student_id)
      hash_from_successful_response get("/ws/v1/student/#{student_id}"), 'student'
    end

    #term resource
    def get_term_by_id(term_id)
      hash_from_successful_response get("/ws/v1/term/#{term_id}"), 'term'
    end
  end
end
