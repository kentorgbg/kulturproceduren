$('#tab1').click(function (e) {
  alert('tab1');
  e.defaultPrevented();
});

$('#tab2').click(function (e) {
  alert('tab2');
  e.defaultPrevented();
});

$('#tab3').click(function (e) {
  alert('tab3');
  e.defaultPrevented();
});
