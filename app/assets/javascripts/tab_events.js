$('#tab1').click(function (e) {
  alert("tab1");
  e.defaultPrevented();
  $(this).tab('show');
})

$('#tab2').click(function (e) {
  alert("tab2");
  e.defaultPrevented();
  $(this).tab('show');
})

$('#tab3').click(function (e) {
  alert("tab3");
  e.defaultPrevented();
  $(this).tab('show');
})
