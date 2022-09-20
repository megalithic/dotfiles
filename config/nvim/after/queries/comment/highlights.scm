; extends

(tag ((name) @_name (#match? @_name "TODO") (":" @CommentTasksTodo)))
(tag ((name) @_name (#match? @_name "FIXME") (":" @CommentTasksFixme)))
(tag ((name) @_name (#match? @_name "NOTE") (":"  @CommentTasksNote)))
(tag ((name) @_name (#match? @_name "REF") (":"  @CommentTasksRef)))
