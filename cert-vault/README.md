# Course Certification System Smart Contract

This Clarity smart contract provides a decentralized system for managing online courses, student enrollments, and certifications. It allows course instructors to create and manage courses, enroll students, issue certifications upon course completion, and verify those certifications. 

The system includes functionality for:
- Course creation and management
- Student enrollment in courses
- Certification issuance upon course completion
- Verification of issued certifications

## Features
1. **Course Management**:
   - **Create Course**: Instructors can create courses with a title, description, price, and metadata URI.
   - **Update Course**: Instructors can update their course details (e.g., price, title, description, and active status).
  
2. **Student Enrollment**:
   - **Enroll in Course**: Students can enroll in active courses by paying the course price in STX.
   - **Check Enrollment**: Track students enrolled in specific courses.

3. **Certification**:
   - **Issue Certificate**: Instructors can issue a certificate to students upon completion of a course, providing a score and metadata URI.
   - **Verify Certificate**: Anyone can verify the authenticity of a student's certificate.

4. **Access Control**:
   - Only the contract owner and authorized instructors can create or manage courses.
   - Only course instructors can issue certificates for their courses.

## Contract Functions

### Public Functions

#### `initialize(owner)`
- **Description**: Initializes the contract and sets the contract owner.
- **Arguments**: 
  - `owner`: The principal that will be set as the owner of the contract.
  
#### `create-course(title, description, price, metadata-uri)`
- **Description**: Creates a new course.
- **Arguments**:
  - `title`: The title of the course.
  - `description`: A detailed description of the course.
  - `price`: The price of the course in microstacks.
  - `metadata-uri`: A URI to additional course metadata (optional).
  
#### `update-course(course-id, title, description, price, metadata-uri, active)`
- **Description**: Updates an existing course.
- **Arguments**:
  - `course-id`: The ID of the course to update.
  - `title`: The new title of the course.
  - `description`: The new description of the course.
  - `price`: The new price of the course.
  - `metadata-uri`: New URI to additional course metadata (optional).
  - `active`: Boolean indicating if the course is active.

#### `enroll-in-course(course-id)`
- **Description**: Allows a student to enroll in an active course by paying the course price.
- **Arguments**:
  - `course-id`: The ID of the course to enroll in.

#### `issue-certificate(student, course-id, score, metadata-uri)`
- **Description**: Issues a certificate to a student upon successful course completion.
- **Arguments**:
  - `student`: The principal of the student receiving the certificate.
  - `course-id`: The ID of the course for which the certificate is being issued.
  - `score`: The score received by the student.
  - `metadata-uri`: A URI to additional certificate metadata (optional).

#### `get-course-details(course-id)`
- **Description**: Fetches the details of a course by its ID.
- **Arguments**:
  - `course-id`: The ID of the course to fetch.
  
#### `get-certificate(student, course-id)`
- **Description**: Fetches the certificate details for a student and a course.
- **Arguments**:
  - `student`: The principal of the student.
  - `course-id`: The ID of the course for which to fetch the certificate.
  
#### `get-student-courses(student)`
- **Description**: Fetches all courses a student is enrolled in.
- **Arguments**:
  - `student`: The principal of the student.

#### `verify-certificate(student, course-id)`
- **Description**: Verifies the authenticity of a certificate.
- **Arguments**:
  - `student`: The principal of the student.
  - `course-id`: The ID of the course for certificate verification.

### Private Functions

#### `is-authorized(user)`
- **Description**: Checks if the provided user is authorized (i.e., the contract owner or an instructor).
  
#### `to-ascii(value)`
- **Description**: Converts a numeric value to its ASCII string representation.

#### `is-valid-price(price)`
- **Description**: Validates if a price is within the acceptable range.

#### `is-valid-course-id(course-id)`
- **Description**: Validates the course ID to ensure it is within the acceptable range.

#### `is-valid-string-length(str)`
- **Description**: Validates the length of a string to ensure it meets the required minimum.

---

## Error Codes

| Error Code              | Description                           |
|-------------------------|---------------------------------------|
| `ERR-NOT-AUTHORIZED`     | The caller is not authorized to perform the action. |
| `ERR-ALREADY-INITIALIZED`| The contract has already been initialized. |
| `ERR-NOT-INITIALIZED`    | The contract has not been initialized. |
| `ERR-WRONG-PRICE`        | The price provided is invalid.        |
| `ERR-COURSE-NOT-FOUND`   | The course does not exist.            |
| `ERR-ALREADY-ENROLLED`   | The student is already enrolled in the course. |
| `ERR-NOT-ENROLLED`       | The student is not enrolled in the course. |
| `ERR-INVALID-SCORE`      | The score provided is invalid.        |
| `ERR-ALREADY-CERTIFIED`  | The student has already received a certificate for this course. |
| `ERR-INVALID-INPUT`      | The provided input is invalid.        |

## Security Considerations

- Only the contract owner or authorized instructors can perform course creation or certification issuance.
- Only enrolled students can receive a certificate.
- Price validation ensures that course prices are within a reasonable range.

## Deployment Instructions

1. **Install Clarinet**: Ensure that you have [Clarinet](https://github.com/hiRoFaK/clarinet) installed for local testing and deployment.
   
2. **Deploy the Contract**:
   - Use Clarinet's deployment commands to deploy the contract to the Stacks network.
   
3. **Interact with the Contract**:  
   - After deployment, you can interact with the contract by calling the public functions using Clarinet or other tools that support Stacks smart contracts.

## Usage Example

Here’s an example of how to use the contract’s functions:

1. **Initialize the Contract**:
   ```clarinet
   (initialize "contract-owner-principal")
   ```

2. **Create a Course**:
   ```clarinet
   (create-course "Blockchain 101" "Learn the basics of blockchain technology." 1000 "http://example.com/course/metadata")
   ```

3. **Enroll a Student**:
   ```clarinet
   (enroll-in-course 1)  ;; Assuming the course ID is 1
   ```

4. **Issue a Certificate**:
   ```clarinet
   (issue-certificate "student-principal" 1 85 "http://example.com/certificate/metadata")
   ```

5. **Verify a Certificate**:
   ```clarinet
   (verify-certificate "student-principal" 1)
   ```