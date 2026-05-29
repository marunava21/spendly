document.addEventListener("DOMContentLoaded", () => {
    const images = document.querySelectorAll('.screen-img');
    const title = document.getElementById('ad-title');
    const subtitle = document.getElementById('ad-subtitle');
    const phone = document.querySelector('.phone');

    let currentIndex = 0;

    // Advertising copy mapping for each image (customize as needed)
    const adCopy = [
        {
            title: "Track Everything",
            subtitle: "View your daily expenses at a glance.",
            transform: "rotateX(5deg) rotateY(-15deg)"
        },
        {
            title: "Beautiful Calendar",
            subtitle: "Visualize your spending habits over the month.",
            transform: "rotateX(10deg) rotateY(15deg)"
        },
        {
            title: "Track IOUs",
            subtitle: "Never forget who owes you money again.",
            transform: "rotateX(-5deg) rotateY(-20deg)"
        },
        {
            title: "Monitor Investments",
            subtitle: "Keep tabs on your portfolio seamlessly.",
            transform: "rotateX(15deg) rotateY(20deg)"
        },
        {
            title: "Smart Logging",
            subtitle: "Add transactions with attachments in seconds.",
            transform: "rotateX(0deg) rotateY(0deg) scale(1.1)"
        }
    ];

    function changeSlide() {
        // Fade out text
        title.style.opacity = 0;
        subtitle.style.opacity = 0;

        // Hide current image
        images[currentIndex].classList.remove('active');

        // Increment index
        currentIndex = (currentIndex + 1) % images.length;

        setTimeout(() => {
            // Update text
            title.innerText = adCopy[currentIndex].title;
            subtitle.innerText = adCopy[currentIndex].subtitle;
            
            // Fade in text
            title.style.opacity = 1;
            subtitle.style.opacity = 1;

            // Show new image
            images[currentIndex].classList.add('active');

            // Rotate phone to new 3D position
            phone.style.transform = adCopy[currentIndex].transform;
        }, 500); // Wait for fade out
    }

    // Set initial text and position
    title.innerText = adCopy[0].title;
    subtitle.innerText = adCopy[0].subtitle;
    phone.style.transform = adCopy[0].transform;

    // Run slideshow every 4 seconds
    setInterval(changeSlide, 4000);
});
