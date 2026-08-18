
const button=document.querySelector('.menu-button');
const nav=document.querySelector('.main-nav');
if(button&&nav){
  button.addEventListener('click',()=>{
    const open=nav.classList.toggle('open');
    button.setAttribute('aria-expanded',String(open));
  });
  nav.querySelectorAll('a').forEach(a=>a.addEventListener('click',()=>{
    nav.classList.remove('open');
    button.setAttribute('aria-expanded','false');
  }));
}

document.querySelectorAll('[data-year]').forEach(el=>{
  el.textContent=new Date().getFullYear();
});

const carousel=document.querySelector('[data-carousel]');
if(carousel){
  const slides=[...carousel.querySelectorAll('.carousel-slide')];
  const dots=[...carousel.querySelectorAll('[data-dot]')];
  const prev=carousel.querySelector('[data-prev]');
  const next=carousel.querySelector('[data-next]');
  let current=0;
  let timer;

  const show=(index)=>{
    current=(index+slides.length)%slides.length;
    slides.forEach((slide,i)=>slide.classList.toggle('active',i===current));
    dots.forEach((dot,i)=>dot.classList.toggle('active',i===current));
  };

  const restart=()=>{
    clearInterval(timer);
    timer=setInterval(()=>show(current+1),6000);
  };

  prev?.addEventListener('click',()=>{show(current-1);restart();});
  next?.addEventListener('click',()=>{show(current+1);restart();});
  dots.forEach((dot,i)=>dot.addEventListener('click',()=>{show(i);restart();}));
  carousel.addEventListener('mouseenter',()=>clearInterval(timer));
  carousel.addEventListener('mouseleave',restart);
  show(0);
  restart();
}
