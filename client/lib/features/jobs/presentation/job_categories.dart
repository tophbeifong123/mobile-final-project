/// Closed category list shared by the company job form and the student filter.
const List<String> jobCategories = [
  'IT & Software',
  'Design & UX/UI',
  'Marketing',
  'Data',
];

bool isJobCategory(String value) => jobCategories.contains(value);
